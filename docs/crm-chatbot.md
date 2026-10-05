# Assistente de CRM (chatbot)

Um painel lateral onde o usuário pergunta, em português, sobre os dados de CRM do **workspace
atual** (contas, contatos, negócios e atividades). As respostas vêm da API do Claude com tool use.
Nesta versão o assistente **só lê**: não existe ferramenta que crie, altere ou apague nada.
Decisões e alternativas no [ADR 0006](adr/0006-crm-chatbot-tool-use.md).

## Como funciona

```
Painel (ChatPanelComponent) ──POST /chat_sessions/:id/chat_messages──▶ ChatMessagesController
                                                                         │ rate limit por usuário
                                                                         │ policy_scope + authorize :ask?
                                                                         ▼
                                                                    Chat::Ask
                                                                         │ valida texto, reserva a sessão,
                                                                         │ DomainEvent chat.message_sent
                                                                         ▼
◀── Turbo Stream: pergunta + "Pensando…"                          ChatReplyJob (Solid Queue)
                                                                         │ relê workspace, membership, sessão
                                                                         ▼
                                                                    Chat::Reply ──HTTPS──▶ api.anthropic.com
                                                                         │  loop de tool use (máx. 5 voltas)
                                                                         │  Chat::Tools(workspace:)
                                                                         ▼
◀── broadcast Turbo Stream [sessão, :chat, user_id]: resposta, remove "Pensando…"
```

- **Abrir:** botão de brilho na topbar. O painel é um `<aside popover>` nativo com um
  `turbo-frame` lazy que carrega `/chat_sessions` (sessão mais recente do usuário) só quando abre.
- **Sessões:** `ChatSession` pertence a workspace + usuário. "Nova conversa" cria outra.
  Cada usuário vê só as próprias sessões, mesmo dentro do mesmo workspace.
- **Mensagens:** `ChatMessage` com `role` `user`/`assistant`/`tool`, `content` jsonb (blocos no
  formato da API) e `tokens_in`/`tokens_out` da resposta que gerou a mensagem. A UI mostra só os
  blocos de texto de `user` e `assistant`; resultados de ferramenta ficam no banco, não na tela.
- **Contexto reenviado:** só o texto das últimas 20 mensagens de usuário/assistente da sessão.
  Blocos de ferramenta de perguntas anteriores não voltam ao modelo.
- **Uma pergunta por vez por sessão:** `reply_started_at` é reservado com um `UPDATE` condicional
  antes de enfileirar e liberado pelo job no `ensure`. Segunda pergunta durante a resposta recebe
  409 com aviso. Reserva órfã (worker morreu) expira em 2 minutos.
- **Enter envia, Shift+Enter quebra linha** (`chat_controller.js`); o botão fica desabilitado
  durante o envio e o campo só é limpo se o servidor aceitou.

## Ferramentas

Todas recebem o `workspace` do servidor. Nenhum schema tem parâmetro de workspace.

| Ferramenta | Parâmetros | Devolve | Limites |
|---|---|---|---|
| `search_contacts` | `query` | id, nome, email, telefone, cargo, nome da conta | 10 linhas; busca em nome/email/cargo |
| `search_accounts` | `query` | id, nome, setor, site, notas (trecho) | 10 linhas; busca em nome/setor |
| `list_deals` | `stage`, `status` (`open`/`won`/`lost`), `closing_before` (AAAA-MM-DD), todos opcionais | id, título, status, etapa, valor, moeda, fechamento previsto, conta | 10 linhas, ordem por fechamento previsto |
| `deal_summary` | `deal_id` | negócio + contato + 5 atividades mais recentes | `not found` para id de outro workspace ou inexistente |
| `recent_activities` | `limit` (1–20, padrão 10) | id, tipo, assunto, corpo (trecho), data, negócio | máximo 20 |

- Busca é `ILIKE` com `sanitize_sql_like`: `%` e `_` são literais. `query` vazia ou com mais de
  100 caracteres volta erro.
- `notes` e `body` são cortados em 300 caracteres.
- Conta, contato, etapa ou negócio associado de outro workspace aparece como `null`.
- Argumento inválido (status fora da lista, data malformada, id não inteiro) e nome de ferramenta
  desconhecido viram `tool_result` com `is_error: true`; o modelo lê o erro e segue.

## Segurança

- **Isolamento de tenant no código, não no prompt.** `Chat::Tools` só consulta
  `workspace.<assoc>`. O job relê `Workspace.find_by(id:)`, confere a membership do usuário e busca
  a sessão com `workspace.chat_sessions.find_by(id:, user_id:)`; sem isso, não faz nada.
- **Prompt injection.** O system prompt diz que tudo que vem das ferramentas é dado do CRM, nunca
  instrução. Mesmo que uma nota maliciosa convença o modelo, ele só alcança as 5 ferramentas de
  leitura presas ao workspace.
- **Autorização.** `ChatSessionPolicy`: `index?`/`create?` exigem membership no workspace atual
  (viewer incluso: a feature é de leitura); `show?`/`ask?` exigem ser o dono da sessão no
  workspace atual; `update?`/`destroy?` sempre negados. Sessão de outro workspace ou de outro
  usuário dá 404 (`policy_scope(...).find`).
- **Stream de Turbo** assinada (`turbo_stream_from`) com nome `[sessão, :chat, user_id]`; só quem
  renderizou o painel daquela sessão recebe a assinatura.
- **Rate limit por usuário:** 10 perguntas por minuto por `current_user.id` (`rate_limit` do
  Rails 8, contador no `Rails.cache`). Dois usuários atrás do mesmo IP têm contadores separados.
  Estourou: 429 com mensagem no painel.
- **Auditoria:** cada pergunta aceita gera `DomainEvent` `chat.message_sent` com
  `chat_session_id` e `text_length` no metadata. O texto da pergunta não vai para o evento.
- **Custo:** `tokens_in`/`tokens_out` gravados em toda resposta do modelo, inclusive nas voltas
  intermediárias de ferramenta. O limite de 5 voltas também é um teto de custo por pergunta.
- **Escape:** pergunta e resposta passam por `h` + `simple_format`; HTML vira texto.

## Erros

| Situação | O usuário vê | Código no `Result` |
|---|---|---|
| 429 da API | "O serviço de IA está com muita demanda agora…" | `:rate_limited` |
| 5xx / 529 / falha de rede | "Não consegui falar com o serviço de IA agora…" | `:unavailable` |
| Timeout (30s por chamada, 60s no total) | "A resposta demorou demais…" | `:timeout` |
| Outro erro da API (400 etc.) | "Algo deu errado ao gerar a resposta…" | `:api_error` |
| 5 voltas e o modelo ainda quer ferramenta | "Precisei de consultas demais…" | `:turn_limit` |
| `stop_reason: refusal` | "Não posso ajudar com esse pedido." | `:refused` |
| Chave da API ausente | "O assistente não está configurado…" | `:not_configured` |
| Exceção inesperada no job | mensagem genérica no painel; job re-levanta para o Solid Queue registrar | — |

Todas viram uma mensagem `assistant` na conversa. O client usa `max_retries: 0`: nada de backoff
dormindo dentro do job.

## Como rodar

```bash
# 1. Chave da API em credentials (nunca no código):
EDITOR=vim bin/rails credentials:edit -e development
#   anthropic:
#     api_key: sk-ant-...
#    (fallback: variável ANTHROPIC_API_KEY, útil em CI/containers)

# 2. Modelo (opcional; padrão claude-sonnet-5-5):
export CHAT_MODEL=claude-sonnet-5-5

# 3. Migrations e servidor:
bin/rails db:migrate
bin/rails tailwindcss:build
bin/rails server
bin/jobs   # o worker do Solid Queue precisa estar rodando para a resposta chegar
```

Abra o app, clique no botão de brilho na topbar e pergunte, por exemplo, "quais negócios abertos
fecham nos próximos 30 dias?".

## Testes

```bash
bundle exec rspec spec/services/chat spec/models/chat_session_spec.rb spec/models/chat_message_spec.rb \
  spec/policies/chat_session_policy_spec.rb spec/jobs/chat_reply_job_spec.rb \
  spec/requests/chat_messages_spec.rb spec/requests/chat_sessions_spec.rb \
  spec/components/chat_panel_component_spec.rb spec/system/chat_flow_spec.rb
```

85 exemplos, com a API do Claude simulada pelo WebMock (`spec/support/anthropic.rb`: o VCR ignora
`api.anthropic.com`, o WebMock continua bloqueando qualquer requisição não simulada, e os corpos
enviados ficam em `anthropic_bodies` para asserção). Cobrem:

- **Tools:** id de negócio de outro workspace devolve exatamente o mesmo resultado que id
  inexistente; buscas e listagens só trazem o workspace atual; `%`/`_` literais; limites de linha;
  status/data inválidos; associação apontando para outro workspace vira `null`; ferramenta
  desconhecida.
- **Reply:** modelo vindo de `CHAT_MODEL`, system prompt e as 5 ferramentas no request; tool use
  executado no servidor com `tool_use_id` correto; para no teto de 5 chamadas; ferramenta fora da
  allowlist não escreve nada; 429, 529, 500, 400, timeout de rede, deadline total e chave ausente
  viram mensagem amigável; tokens somados por volta.
- **Job:** broadcast da resposta e remoção do indicador na stream da sessão; 429 não levanta
  exceção e aparece na conversa; erro inesperado libera a sessão; usuário sem membership e sessão
  de outro workspace não chamam a API.
- **Request:** um único enqueue com ids do servidor (um `workspace_id` enviado pelo cliente é
  ignorado), Turbo Stream da pergunta, DomainEvent, texto vazio, segunda pergunta durante a
  resposta, 404 para sessão de outro workspace e de outro usuário, viewer pode perguntar, rate
  limit por usuário (separado entre usuários, reseta após a janela).
- **Policy, models, componente** (escape de HTML, payload de ferramenta escondido, indicador
  "Pensando…") e um system spec ponta a ponta (pergunta → job → ferramenta → resposta no histórico).

Os testes foram conferidos quebrando o isolamento de propósito:

- `workspace.deals.find_by` → `Deal.find_by` em `deal_summary`: 2 exemplos falham (o de id
  estrangeiro nas tools e no reply).
- `ChatSessionPolicy::Scope` devolvendo `scope.all`: 4 exemplos falham (404 cross-workspace e
  cross-user nos requests, e o spec do Scope).

## Limites conhecidos

- **Ainda não rodou contra a API real.** O formato de request/resposta segue o SDK oficial
  (`anthropic` 1.76) e foi exercitado só contra stubs. Primeiro passo antes de chamar de pronto:
  configurar uma chave e fazer algumas perguntas no seed de dev.
- **Somente leitura.** Criar atividade, mover negócio de etapa etc. fica para uma versão com
  confirmação explícita do usuário antes de cada escrita.
- **Sem streaming de tokens.** A resposta aparece inteira quando o loop termina (até 60s).
- **Memória curta.** Só o texto das últimas 20 mensagens volta ao modelo; dados de ferramentas de
  perguntas anteriores não.
- **Corrida rara no indicador.** Se o job terminar antes de o navegador aplicar a resposta do POST,
  o "Pensando…" pode ficar na tela até recarregar o painel. Na prática a chamada à API leva
  segundos e isso não acontece.
- **Rate limit em dev/test é por processo** (`MemoryStore`). Em produção usa Solid Cache.
- **Sem fallback de modelo em recusa** (`stop_reason: refusal`): vira mensagem amigável.
- **Sem retenção.** `chat_messages` cresce sem limite; um job de expurgo por idade vem depois.
