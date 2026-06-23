# 0001 — Auth nativa do Rails 8 em vez de Devise

- Status: Accepted
- Data: 2026-06-18

## Contexto

O Rails 8.0, liberado em setembro de 2024, trouxe um gerador de autenticação nativo:

```bash
bin/rails generate authentication
```

Esse gerador entrega um esqueleto mínimo porém funcional: model `User` com `has_secure_password`, model `Session` DB-backed (sem cookie-store de sessão tradicional), fluxo de password reset via token assinado, mailer básico e a macro `rate_limit` disponível direto no `ActionController::Base`. Tudo em código gerado no app — sem mágica de engine montada.

O PipelineHQ é um CRM B2B multi-tenant em Rails 8 desenvolvido como **projeto de portfólio**. A autenticação é a primeira decisão arquitetural visível do projeto, então a escolha precisa estar bem justificada e exercitar o Rails 8 moderno em profundidade.

Restrições e contexto adicional:

- Mercado BR usa Devise como padrão **há ~15 anos**. Sair desse padrão exige justificativa explícita.
- Existem pelo menos três caminhos viáveis: Devise (+ Devise-Security), Rodauth, ou auth nativa do Rails 8.
- O escopo de segurança não é "login que funciona", e sim "auth production-ready 2026" — o que inclui 2FA, lockout, audit log, sessões revogáveis, etc. (detalhado no ADR 0002).
- Não há equipe — manter cada linha de código de auth é custo direto do autor.

## Decisão

Usar o **gerador nativo de autenticação do Rails 8** (`bin/rails generate authentication`) como base, e construir **camadas de hardening em código próprio por cima** (ver ADR 0002). Sem Devise, sem Rodauth.

## Consequências

### Boas

- **Zero gem extra** na superfície de ataque para o componente mais crítico do app. Auth fica em código que o autor leu inteiro.
- **Controle total do fluxo** — login, logout, criação de sessão, reset e revogação são código no `app/`, sem indireção via engine montada.
- **Sinaliza fluência em Rails 8** para quem avalia o portfólio. Em 2026, usar Devise num projeto novo é o caminho seguro; usar auth nativa com hardening em cima é o caminho que mostra leitura técnica atual.
- **Fácil estender via Plain Old Ruby** — services em `app/services/auth/` retornando `Result.success/failure` se encaixam direto no padrão das 30 Regras (regra 1 e 11). Sem precisar dobrar a API de um framework de terceiros.
- **Alinhado ao princípio "explícito > mágico"** que o próprio Rails 8 vem reforçando (Solid Queue/Cache/Cable também trocam infra opaca por código visível em PG).
- **Onboarding mais barato** para qualquer outro Rails dev que abrir o repo — o fluxo está em `SessionsController`, `User`, `PasswordsController`, não em config de uma engine.

### Ruins / trade-offs

- **Perdemos o ecossistema do Devise.** Módulos como `Confirmable`, `Lockable`, `Trackable`, `Omniauthable`, `Recoverable` e `Timeoutable` precisam ser reimplementados (é exatamente o que o ADR 0002 cobre). Cada um deles é código adicional para manter e testar.
- **Devise tem ~15 anos de battle-testing**, milhares de apps em produção, e CVEs historicamente descobertos e corrigidos rápido. Nossa reimplementação não tem esse track record — depende de testes próprios sólidos e revisão atenta.
- **Cada feature de hardening custa código próprio**. Não é "ativar um módulo" — é escrever model, service, view, mailer, teste. Mais arquivos para manter (~38 no plano do ADR 0002).
- **Risco de "rebuild Devise pior".** Existe um trade-off real entre "fiz na mão para aprender/mostrar" e "reinventei algo que já estava resolvido". Mitigado por escopo claro (10 camadas pré-definidas) e referências cruzadas a implementações conhecidas.
- **Quem chega no repo vai perguntar.** "Por que não usou Devise?" é a primeira reação esperada. Esse ADR é, em parte, a resposta.

### Alternativas consideradas

- **Devise + Devise-Security:** ecossistema mais maduro do BR, módulos prontos para a maior parte do que vamos construir, OmniAuth integrado. Rejeitado porque: (a) carrega décadas de magia (Warden, mappings, hooks) que aumentam a superfície e reduzem visibilidade; (b) Devise-Security não tem o mesmo ritmo de atualização do Devise core; (c) não sinaliza Rails 8 moderno no portfólio; (d) cada customização mais profunda esbarra na API do Devise em vez de em Ruby puro.
- **Rodauth:** tecnicamente o mais robusto dos três — feature set vasto (2FA, account lockout, audit log, JWT, OmniAuth, WebAuthn), arquitetura desacoplada do model, DSL configurável. Rejeitado porque: (a) curva de aprendizado alta, DSL própria de Roda/Rodauth; (b) acoplamento ao Sequel/Roda fora do ecossistema Rails idiomático cria atrito conceitual num app que é Rails canônico no resto; (c) adoção marginal no Brasil — pouca documentação em pt-BR e curva extra pra qualquer dev novo no projeto.
- **Auth nativa "crua" (só o gerador, sem hardening):** rejeitada de saída. O gerador entrega login + sessão + reset, e nada além disso. Sem 2FA, sem lockout, sem audit, sem rate limit cross-process, sem confirmação de email. Em 2026, isso não passa em nenhuma review séria de segurança — e como portfólio sinaliza o oposto do desejado.
