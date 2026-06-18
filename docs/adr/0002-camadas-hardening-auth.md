# 0002 — Camadas de hardening sobre auth nativa

- Status: Accepted
- Data: 2026-06-18

## Contexto

O ADR 0001 fixou a decisão de usar o gerador nativo de autenticação do Rails 8 em vez de Devise. O gerador entrega apenas o básico: model `User` com `has_secure_password`, `Session` DB-backed, password reset por token assinado e a macro `rate_limit` no controller. Tudo o mais — confirmação de email, lockout, 2FA, audit, gestão de sessões ativas, sudo mode, rate limit cross-process — é responsabilidade do app.

Para o PipelineHQ ser **production-ready 2026** (e defensável em review de segurança e em entrevista técnica), precisamos defesa em profundidade. A premissa de design é: **nenhuma camada sozinha é suficiente; o conjunto é**. Se um atacante quebra rate limit, o lockout segura; se passa do lockout, 2FA segura; se passa de 2FA, o audit log denuncia.

Restrições adicionais do projeto:

- **Sem Redis.** Decisão arquitetural do projeto (ortodoxia Rails 8: Solid Queue/Cache/Cable). Toda infra de rate limit, cache, fila precisa rodar em PG.
- **Sem equipe.** Cada arquivo é manutenção própria — escopo precisa ser fechado e bem testado, não aberto e ambicioso.
- **Portfólio sênior.** As camadas precisam ser legíveis em isolado (cada uma é um "capítulo" demonstrável em entrevista).

## Decisão

Implementar **10 camadas de hardening** sobre a auth nativa do Rails 8, todas em código próprio do app, sem Redis:

1. **Email confirmation** — token assinado via `User#generate_token_for(:email_confirmation)`. Sem coluna de DB para token (Rails 8 derruba a necessidade); expiração e propósito embutidos no token.
2. **Account lockout** — 5 falhas de login consecutivas travam a conta por 15 minutos. Contador e `locked_until` no `User`; reset no login bem-sucedido.
3. **Rate limiting cross-process** — `rack-attack` apoiado em **Solid Cache** como backing store. Cobre login, signup, password reset e 2FA. Funciona com múltiplos processos Puma sem Redis.
4. **Strong password validator** — mínimo 12 caracteres, complexidade (maiúscula + minúscula + dígito + símbolo), checagem opcional na **Pwned Passwords API** (k-anonymity). Política de **fail-open** com timeout de 1s: se a Pwned API cai, a validação local segura, e o user não é bloqueado por indisponibilidade externa.
5. **2FA TOTP** — `rotp` para geração/verificação, `rqrcode` para QR code. Secret armazenado em `User#otp_secret` **criptografado via Active Record Encryption** (não plaintext). Padrão `otpauth://` compatível com Google Authenticator, 1Password, Authy.
6. **Backup codes** — **8 códigos single-use** gerados na ativação do 2FA, armazenados com `bcrypt` (mesmo custo da password). Consumo marca o código como usado; rotação completa exige re-ativação do 2FA.
7. **UI de sessões ativas** — tela em `/settings/sessions` listando sessões com user-agent, IP, último acesso. Revoke individual por sessão e botão "revoke all others" que mantém apenas a sessão atual.
8. **Sudo mode** — para ações sensíveis (trocar email, desativar 2FA, gerar novos backup codes, revogar todas sessões), exigir re-autenticação por password recente (≤15min). Timestamp `sudo_until` na sessão.
9. **Audit log assíncrono** — tabela `AuthEvent` (event_type, user_id, ip, user_agent, metadata jsonb, created_at). Eventos publicados via **Solid Queue** para não bloquear a request. **GIN index em `metadata`** para queries operacionais.
10. **Honeypot anti-bot no signup** — campo `nickname` invisível via CSS no formulário. Se preenchido, o submit retorna 200 OK fake (não 4xx), sem criar conta. Sem CAPTCHA, sem fricção para humano.

## Consequências

### Boas

- **Defesa em profundidade real**, não cosmética. Cada camada cobre uma classe distinta de ataque (credential stuffing, brute force, phishing, hijack de sessão, escalada após comprometer cookie, etc.).
- **Tudo via Postgres** — mantém a ortodoxia Rails 8 do projeto e zera o custo operacional de Redis (provisionamento, backup, monitoração, custo no Kamal).
- **Cada camada é testável em isolado** — model spec para lockout, service spec para Pwned, system test para 2FA flow. Casa direto com a regra 29 das 30 Regras.
- **Audit log dá observabilidade real** — `AuthEvent` responde "esse login veio de onde?" e "essa conta foi locada quando?" sem grep em log de aplicação. GIN index em jsonb permite query por payload arbitrário (ex.: "todos os eventos com `failure_reason: 'invalid_otp'` nos últimos 7d").
- **Active Record Encryption no `otp_secret`** garante que vazamento de dump de DB não compromete 2FA dos usuários.
- **Pwned com fail-open** evita o anti-padrão clássico de "dependência externa derruba meu signup". Timeout curto + fallback para validação local.
- **Como portfólio, cada camada é um capítulo demonstrável** — em entrevista, dá para abrir um arquivo de cada vez e explicar a decisão de design.

### Ruins / trade-offs

- **~38 arquivos novos** entre models, services, controllers, views, mailers, jobs, migrations, testes. É código próprio para manter, atualizar e cobrir com testes — não é "ativei um módulo".
- **Pwned Passwords introduz dependência externa.** Mitigado por timeout de 1s e fail-open, mas a checagem efetiva fica indisponível quando a API estiver fora. Aceito.
- **Bcrypt de backup codes no login custa CPU.** Cada tentativa de backup code é um `bcrypt` (cost padrão 12). Custo medido: ~50ms por verificação. Aceitável dado o uso pontual (fallback de 2FA, não fluxo quente).
- **Audit log assíncrono pode perder evento em crash do worker** entre enqueue e flush. Mitigado por persistência da fila em PG via Solid Queue (durável por padrão), mas há uma janela teórica.
- **Sudo mode adiciona fricção real ao usuário** em ações sensíveis. É o ponto. Mas precisa de UX cuidadoso para não virar irritação (mensagem clara do porquê do re-auth).
- **Mais código = mais superfície para bug próprio**. Cada camada é uma chance de errar. Mitigado por testes obrigatórios (regra 29) e revisão pelo `reviewer` contra as 30 Regras.

### Alternativas consideradas

- **Não fazer 2FA agora ("MVP de auth, 2FA depois"):** rejeitado. 2FA é diferenciador concreto em portfólio sênior em 2026 e fecha a classe de ataque mais comum hoje (credential stuffing pós-vazamento). Adiar significa enviar PR de auth sem ele, o que enfraquece o capítulo inteiro.
- **Usar Redis para rate limit (rack-attack padrão):** rejeitado. Redis é dependência operacional não-trivial e contradiz a decisão do projeto de ficar em PG. Solid Cache cobre o caso de uso de rack-attack (TTLs curtos, contadores) sem essa dependência. Se latência virar problema medido, reavaliamos.
- **WebAuthn / Passkeys em vez de (ou além de) TOTP:** adiado para fase 2. Passkey é o futuro, mas implementar bem dobra o escopo do PR de auth (registro de credencial, autenticação, fallback, UX cross-device) e exige decisões sobre `webauthn-ruby` + Stimulus controllers para a API do browser. Por ora, TOTP cobre a defesa principal; Passkey entra como ADR separado depois.
- **`devise-two-factor` standalone (sem o resto do Devise):** rejeitado. Acoplado ao Devise; tirar Devise e manter só essa gem é frankenstein. Reimplementar o caso simples de TOTP em `app/services/auth/` é mais limpo e legível que importar uma gem para isso.
- **Audit síncrono (gravar `AuthEvent` no mesmo request):** rejeitado. Login bem-sucedido precisa ser rápido; gravar evento na request quente adiciona latência sem benefício (audit não precisa ser real-time strict). Solid Queue resolve com durabilidade aceitável.
- **Lockout por IP em vez de por conta:** rejeitado como única defesa — atacante distribuído burla. Lockout por conta (camada 2) + rate limit por IP (camada 3) cobrem ambos os vetores.
