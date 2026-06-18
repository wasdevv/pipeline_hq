# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

**PipelineHQ** é um CRM B2B em Ruby on Rails 8 — pipeline de vendas estilo Pipedrive/HubSpot, sendo construído como projeto de portfólio sênior por um dev em busca de vaga Rails em 2026. O foco é **sinalizar fluência em Rails 8 moderno + decisões deliberadas + segurança real**, não cobertura de features.

**Estado em 2026-06-18:**
- Auth nativa Rails 8 + 10 camadas de hardening: completa, funcionando end-to-end, ~38 arquivos.
- UI: split-screen no login (estilo Linear/Vercel) + toggle de tema dark/light com anti-flash; 6 ViewComponents (AuthShell, AuthHeader, FormField, ButtonPrimary, ButtonSecondary, NavCard).
- 5 scaffolds CRM (Account/Contact/Stage/Deal/Activity) gerados mas SEM relacionamentos `has_many` e SEM multi-tenancy ainda.
- Sem framework de testes instalado (decisão: RSpec, setup pendente).
- 2 ADRs em `docs/adr/` + 4 posts LinkedIn em `posts/` prontos.

## Stack

- **Ruby 4.0.5** via rbenv (`.ruby-version`). Para usar: `export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init - bash)"`.
- **Rails 8.1.3**.
- **PostgreSQL** local — `host=localhost user=postgres password=postgres` em dev/test.
- **Tailwind CSS v4** via `tailwindcss-rails` (config em `app/assets/tailwind/application.css` com `@custom-variant dark` para dark mode por classe).
- **Propshaft** + **Importmap** (sem bundler JS, sem npm).
- **Hotwire**: Turbo + Stimulus. Stimulus controllers auto-carregados via `eagerLoadControllersFrom`.
- **Solid Queue / Cache / Cable** — tudo no PG, sem Redis.
- **Kamal 2** (deploy).
- **Rubocop omakase**, **Brakeman**, **bundler-audit** (já no projeto).
- **Testes: RSpec instalado + configurado.** Stack: rspec-rails, factory_bot_rails, faker, shoulda-matchers, capybara, selenium-webdriver (Selenium Manager nativo Rails 8), database_cleaner-active_record, timecop, webmock, vcr, rails-controller-testing, rspec-benchmark, simplecov (branch coverage). Locale padrão pt-BR via rails-i18n.

## Gems instaladas (Gemfile)

**Core**: rails, pg, puma, propshaft, importmap-rails, turbo-rails, stimulus-rails, tailwindcss-rails, jbuilder, bcrypt, image_processing, tzinfo-data, solid_cache/queue/cable, bootsnap, kamal, thruster.

**Auth hardening**: rack-attack, pwned, rotp, rqrcode.

**Safety/UI**: strong_migrations, money-rails, view_component.

**i18n**: rails-i18n.

**Dev**: debug, bundler-audit, brakeman, rubocop-rails-omakase, web-console, letter_opener, bullet, annotaterb, rack-mini-profiler, memory_profiler, flamegraph, stackprof.

**Test stack**: rspec-rails, factory_bot_rails, faker, shoulda-matchers, capybara, selenium-webdriver, database_cleaner-active_record, timecop, webmock, vcr, rails-controller-testing, rspec-benchmark, simplecov.

## Comandos comuns

```bash
# Ativar rbenv (sempre antes de qualquer rails/bundle)
export PATH="$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init - bash)"

# Dev local
bin/rails server                 # web only (sem watcher Tailwind)
bin/dev                          # web + tailwindcss:watch via foreman (pode ter problemas em WSL)
bin/rails tailwindcss:build      # build manual do CSS — rode após adicionar classes novas
bin/rails console
bin/rails db:migrate db:seed
bin/rails db:reset

# Auth helper paths principais (rotas)
GET  /                           # home autenticado
GET  /session/new                # login (split-screen)
POST /session                    # login submit
GET  /sign_up/new                # signup
GET  /confirmations/:token       # confirma email
GET  /two_factor                 # show 2FA (precisa sudo)
GET  /two_factor/enroll          # ativa 2FA (QR + secret)
GET  /two_factor/verify          # passo 2FA no login
GET  /sessions_management        # sessões ativas
GET  /sudo/new                   # entra em sudo mode

# Geradores
bin/rails generate scaffold Lead account:references score:integer
bin/rails generate migration AddIndexToLeadsScore
bin/rails generate authentication      # auth nativa Rails 8 (JÁ RODOU)

# Qualidade
bin/rubocop                # lint
bin/rubocop -a             # autocorrect seguro
bin/brakeman               # security scan
bin/bundler-audit          # CVEs em gems

# Testes (RSpec)
bundle exec rspec                   # suite completa
bundle exec rspec spec/models       # só specs de model
bundle exec rspec spec/services/sessions/sign_in_spec.rb:42  # spec específico
open coverage/index.html            # cobertura SimpleCov (gerada após cada run)
FACTORY_LINT=1 bundle exec rspec    # valida todas as factories antes de rodar

# Jobs (Solid Queue)
bin/jobs                   # worker em foreground

# Credentials (ActiveRecord encryption já configurado em dev/test)
EDITOR='cp /tmp/some_yml' bin/rails credentials:edit -e development
```

## Como rodar do zero (próximo dev na máquina)

```bash
# Pré-requisitos: rbenv + Postgres rodando em localhost:5432 (user=postgres pw=postgres)
cd /home/was/projetos/pipeline_hq
export PATH="$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init - bash)"
bundle install
bin/rails db:create db:migrate db:seed
bin/rails tailwindcss:build
bin/rails server

# Acesse http://localhost:3000
# Login: demo@pipelinehq.test / DemoUser!2026PipelineHQ (criado pelo seed)
```

---

## Arquitetura — estado atual detalhado

### Auth hardening (completa)

| Camada | Arquivos principais |
|---|---|
| Login + sessão | `app/controllers/sessions_controller.rb`, `app/services/sessions/sign_in.rb`, `app/controllers/concerns/authentication.rb` |
| Signup + honeypot | `app/controllers/registrations_controller.rb`, `app/services/users/register.rb`, `app/javascript/controllers/honeypot_controller.js` |
| Email confirmation (token assinado) | `app/controllers/confirmations_controller.rb`, `app/services/users/confirm.rb`, `User.generates_token_for(:email_confirmation, expires_in: 24.hours)`, `app/mailers/confirmations_mailer.rb` |
| Lockout (5 falhas / 15min) | `app/services/users/track_failed_attempt.rb`, `app/services/users/lock.rb`, `app/services/users/reset_failed_attempts.rb`, `User::LOCK_THRESHOLD/LOCK_DURATION` |
| Rate limit cross-process | `config/initializers/rack_attack.rb` (usa `Rails.cache` — vira Solid Cache em prod, MemoryStore em dev) |
| Password strength + Pwned | `app/validators/password_strength_validator.rb`, `app/services/passwords/breach_check.rb` (fail-open, timeout 1s) |
| 2FA TOTP + 8 backup codes | `app/services/two_factor/*` (enroll/confirm/verify/disable/generate_backup_codes/regenerate_backup_codes), `app/controllers/two_factors_controller.rb`, secret criptografado via `encrypts :otp_secret` (AR encryption) |
| Sessões ativas (revoke) | `app/controllers/sessions_management_controller.rb` (`Session.except_current(current)` scope) |
| Sudo mode (15min) | `app/controllers/concerns/sudo_required.rb`, `app/controllers/sudo_sessions_controller.rb`, `app/services/sessions/start_sudo.rb` |
| Audit log assíncrono | `app/models/auth_event.rb` (KINDS frozen), `app/services/auth_events/record.rb` → `AuthEventJob` (Solid Queue, `discard_on DeserializationError`) |

**Schema relevante:**
- `users`: name, email_address (uniq), password_digest, confirmed_at, confirmation_sent_at, failed_attempts (default 0), locked_at, otp_secret (encrypted), otp_enabled_at, otp_backup_codes (string[] — bcrypt hashes).
- `sessions`: user_id, ip_address, user_agent, last_active_at, sudo_until, otp_verified_at.
- `auth_events`: user_id (nullable), email_address, kind (frozen list), ip_address, user_agent, metadata (jsonb, GIN-indexed), created_at.

**Índices**: parciais em users (`locked_at WHERE NOT NULL`, `confirmed_at WHERE NULL`), composto em sessions (`user_id, last_active_at`), 4 em auth_events (incluindo GIN no metadata). Todos criados em **migrations separadas** com `disable_ddl_transaction!` + `algorithm: :concurrently` (padrão sênior, mesmo em tabela vazia).

**Cookie de sessão**: `httponly: true, secure: Rails.env.production?, same_site: :lax`.

### UI / ViewComponents

| Component | Onde usado |
|---|---|
| `AuthShellComponent` | Wrapper centralizado V+H pra todas as views de auth exceto login |
| `AuthHeaderComponent` | Título + subtítulo no topo dos forms auth |
| `FormFieldComponent` | Input + label (form-bound ou form-less; `class_extra` pra customização) |
| `ButtonPrimaryComponent` | Botão primário preto (light) / branco (dark) |
| `ButtonSecondaryComponent` | Botão outline + variante `:danger` (vermelho) |
| `NavCardComponent` | Cards de navegação no dashboard |

**Tema dark/light:**
- Tailwind v4 com `@custom-variant dark (&:where(.dark, .dark *))` em `app/assets/tailwind/application.css`.
- Anti-flash inline script no `<head>` do `application.html.erb` lê `localStorage["theme"]` e aplica classe `dark` no `<html>` antes do CSS carregar.
- `app/javascript/controllers/theme_controller.js` faz toggle + persiste em localStorage.
- Botão flutuante no canto superior direito (`fixed right-4 top-4 z-50`) em todas as páginas.

**Layout especial:**
- `sessions/new.html.erb` mantém **split-screen Linear/Vercel** (painel esquerdo com gradiente indigo→fuchsia + wordmark + tagline; painel direito com form). NÃO usa `AuthShellComponent` — é única.

### Models CRM (scaffolds, sem regras ainda)

| Modelo | Campos principais | Pendência crítica |
|---|---|---|
| `Account` | name, industry, website, notes | `has_many :contacts, :deals`, `workspace_id` |
| `Contact` | account_id, name, email, phone, role | `inverse_of:`, `workspace_id` |
| `Stage` | name, position, color | `has_many :deals`, unicidade de position por workspace |
| `Deal` | title, account_id, contact_id, stage_id, amount_cents, currency, expected_close_on, status | `has_many :activities`, money via Money-Rails, `workspace_id` |
| `Activity` | deal_id, kind, subject, body, occurred_at | `inverse_of:`, `workspace_id` |

### Service Object pattern (em uso)

`app/services/result.rb` define `Result.success(code, payload)` / `Result.failure(code, errors)`. Todos os services seguem `Class.call(...)` → `Result`.

Exemplo canônico: `app/services/sessions/sign_in.rb`.

```ruby
class Sessions::SignIn
  def self.call(...) = new(...).call
  def initialize(email_address:, password:, request:); end
  def call
    # returns Result.success(:signed_in, user) | Result.failure(:locked) | ...
  end
end
```

---

## Mapa rápido do código

```
app/
├── assets/tailwind/application.css   # imports + @custom-variant dark
├── components/                        # 6 ViewComponents
├── controllers/
│   ├── concerns/{authentication,sudo_required}.rb
│   ├── home_controller.rb
│   ├── {sessions,registrations,confirmations,passwords,two_factors,sudo_sessions,sessions_management}_controller.rb
│   └── {accounts,contacts,deals,stages,activities}_controller.rb  # scaffolds
├── jobs/auth_event_job.rb
├── javascript/controllers/            # Stimulus: theme, honeypot, otp-input
├── mailers/confirmations_mailer.rb
├── models/{user,session,current,auth_event,account,contact,stage,deal,activity}.rb
├── services/
│   ├── result.rb
│   ├── auth_events/record.rb
│   ├── passwords/breach_check.rb
│   ├── users/{register,confirm,lock,track_failed_attempt,reset_failed_attempts,send_confirmation_email}.rb
│   ├── sessions/{sign_in,touch_activity,start_sudo}.rb
│   └── two_factor/{enroll,confirm,verify,disable,generate_backup_codes,regenerate_backup_codes}.rb
├── validators/password_strength_validator.rb
└── views/
    ├── layouts/application.html.erb   # anti-flash script + theme toggle
    ├── shared/_flash.html.erb
    ├── home/show.html.erb
    └── {sessions,registrations,confirmations,passwords,two_factors,sudo_sessions,sessions_management}/*.erb

config/
├── credentials/{development,test}.{key,yml.enc}   # AR encryption keys já plantadas
├── initializers/{rack_attack,bullet}.rb
└── routes.rb                          # todas as rotas de auth + CRM scaffolds

db/
├── migrate/                           # 13 migrations: 5 CRM + auth base + 6 hardening (3 cols + 3 indexes)
└── seeds.rb                           # cria demo@pipelinehq.test

docs/adr/
├── 0001-auth-nativa-rails-8.md
└── 0002-camadas-hardening-auth.md

posts/                                 # 4 posts LinkedIn (anúncio + 3 seguimento)

spec/
├── config_spec.rb                  # smoke: env, locale, factory, WebMock
├── factories/users.rb              # :user + traits :unconfirmed, :locked, :with_2fa
├── rails_helper.rb                 # FactoryBot, Shoulda, DatabaseCleaner, WebMock
├── spec_helper.rb                  # SimpleCov no topo (branch coverage)
└── support/passwords.rb            # stub global Passwords::BreachCheck

.claude/agents/                        # 10 subagents project-level (coordinator, planner, architect, rails-engineer, frontend-engineer, data-agent, tester, reviewer, writer, summariser)
```

## Seed / credenciais demo

```
Email:    demo@pipelinehq.test
Senha:    DemoUser!2026PipelineHQ
```

Criado por `db/seeds.rb` (só em dev). User criado com `confirmed_at: Time.current`, sem 2FA.

---

## 30 Regras de Ouro

Canônicas e referenciadas por todos os subagents. Mudar uma regra exige atualizar este arquivo e cumprir nos próximos PRs.

### Arquitetura & DRY (1-7)
1. **Controllers finos** — > 5 linhas de lógica = Service Object em `app/services/`.
2. **Regra do três** — extraia abstração só na **3ª** duplicação real. Antes disso, três linhas iguais é melhor do que abstração prematura.
3. **ViewComponent** quando o mesmo bloco de UI aparece em ≥2 contextos.
4. **Query Object** em `app/queries/` quando há ≥2 joins ou ≥3 condições combinadas.
5. **Form Object** para forms multi-modelo ou com validação cross-record.
6. **Decorator/Presenter** para lógica de apresentação fora do model.
7. **Concerns** só pra comportamento compartilhado entre 3+ classes — nunca para "organizar" um único model.

### Código Ruby (8-14)
8. Método > 10 linhas exige justificativa; > 15 = refatorar.
9. Classe > 100 linhas é candidata a quebrar.
10. Sem `if/elsif` com 3+ ramos — use hash lookup, polimorfismo ou Strategy.
11. Sem retornar `nil` pra indicar erro — use `Result.success(...)` / `Result.failure(...)`.
12. `# frozen_string_literal: true` no topo de todo `.rb` novo.
13. Constantes em `SCREAMING_SNAKE_CASE`, sempre congeladas (`.freeze`).
14. `&.` (safe nav) só onde valor pode legitimamente ser `nil` — nunca como "talvez exista".

### Rails Patterns (15-20)
15. `belongs_to` com `inverse_of:` quando há `has_many` bidirecional.
16. `dependent:` sempre explícito (`destroy`, `delete_all`, `restrict_with_error`, `nullify`).
17. `enum` para status — sintaxe Rails 7+: `enum :status, { draft: 0, ... }, default: :draft`.
18. Callbacks só pra integridade interna do model. Side effect externo (email, webhook, job) = Service Object.
19. Scope nomeado expressivo (`Deal.open_in(workspace)`), nunca `where(...)` solto em controller.
20. Sempre `current_workspace.deals.find(id)` — nunca `Deal.find(params[:id])` (tenant leak).

### PostgreSQL (21-25)
21. Toda FK indexada; composto em `(workspace_id, status, created_at)` para listagens hot.
22. Constraints no DB: `NOT NULL`, `CHECK`, `FK`, `UNIQUE`. Validação Ruby é defesa secundária.
23. Índice em tabela grande (>100k rows): `disable_ddl_transaction!` + `algorithm: :concurrently`. **Convenção do projeto: aplicar mesmo em tabela vazia, em migration separada das colunas** (lição da feature de auth).
24. Dinheiro: `amount_cents:integer` + `currency:string` + Money-Rails. `decimal` proibido para valores monetários.
25. Use `strong_migrations` (já no projeto) pra catch automático de migration insegura em CI.

### Performance (26-28)
26. **Zero N+1** — `bullet` ativo em dev; toda listagem com `includes`/`preload`.
27. **Counter cache** pra contagem hot (`deals_count` em Account).
28. `find_each` / `in_batches` para coleções > 1000 registros.

### Testes & Segurança (29-30)
29. Cobertura mínima por feature: model (validações/scopes), service (cada caminho do Result), 1 system test ponta-a-ponta. Mock apenas em `app/services/ai/` e HTTP externo (WebMock/VCR).
30. Autorização explícita por ação — `current_user` autenticado não basta. Use Pundit ou policy class plain Ruby; scoping multi-tenant via `current_workspace`.

---

## Gems recomendadas (ainda a adicionar)

**Arquitetura / qualidade**
- `pundit` — autorização por policy class
- `pagy` — paginação rápida
- `dry-monads` — `Result`/`Maybe` se quiser DSL pronto (atualmente: `app/services/result.rb` plain Ruby)

**PostgreSQL**
- `pg_search` — full-text com tsvector
- `scenic` — materialized views versionadas
- `fx` — funções e triggers PG em migrations

**Domínio**
- `paper_trail` ou `audited` — audit log para domain (auth já tem `auth_events`)
- `discard` — soft delete por flag

**Observabilidade**
- `lograge` — logs JSON estruturados
- `marginalia` — origem da query como comentário SQL

**Testes (RSpec setup pendente)**
- `rspec-rails`, `factory_bot_rails`, `faker`, `capybara`, `selenium-webdriver`, `shoulda-matchers`

---

## Workflow com subagents — Hub-and-Spoke

**Princípio:** o `coordinator` é o **hub**. **Subagents nunca chamam outros subagents** — só reportam ao coordinator. Conflito = coordinator resolve (citando regra) ou escala ao usuário.

### Roster

| Agent | Modelo | Função |
|---|---|---|
| `coordinator` | opus | Único que invoca outros. Decompõe, decide estratégia, agrega |
| `planner` | opus | Decompõe pedido vago em roadmap/milestones (vem antes do architect) |
| `architect` | opus | Design técnico (modelos, serviços, índices, trade-offs) |
| `rails-engineer` | sonnet | Implementa backend Rails |
| `frontend-engineer` | sonnet | Tailwind v4, Hotwire UI, ViewComponent, acessibilidade |
| `data-agent` | sonnet | Postgres avançado: índices, EXPLAIN, materialized views, seeds |
| `tester` | sonnet | Escreve e roda testes (vai instalar RSpec na primeira chamada) |
| `reviewer` | sonnet | Code review enforçando as 30 regras |
| `writer` | sonnet | README, ADR, CHANGELOG, post LinkedIn |
| `summariser` | haiku | Condensa output longo |

### Fluxo padrão

```
1. DECOMPOSE — Coordinator lê CLAUDE.md, decompõe em TaskCreate
2. ASSESS COMPLEXITY
   Trivial   (1 arquivo, sem decisão)            → single agent
   Normal    (2-5 arquivos, mesmo domínio)       → 2-3 agents em sequência
   Complexa  (transversal, ambíguo, novo escopo) → planner + agents em paralelo
3. STRATEGY
   Single:     rails-engineer (ou agente específico)
   Sequencial: architect → rails-engineer → tester → reviewer
   Paralela:   architect + frontend-engineer + data-agent simultâneos
4. AGGREGATE — merge, rank, resolve conflicts (>2k tokens passa pelo summariser)
5. CLOSE — reviewer ✅ → writer atualiza docs → coordinator atualiza "Lições aprendidas"
```

### Saída fixa de todo subagent

```
## Resumo
## Arquivos tocados
## Decisões/Trade-offs
## Bloqueios / Próximo passo sugerido
```

### Quando spawnar agents vs fazer inline

- **Inline (eu mesmo)**: edits triviais (1-3 arquivos), correções pontuais reportadas por reviewer, smoke tests, fixes de typo/lint.
- **Spawn agent**: 5+ arquivos novos, paralelização real (backend + frontend simultâneos), tarefas que se beneficiam de contexto isolado.
- **Cuidado**: cada spawn re-deriva contexto e custa tokens. Não spawn por preguiça de codar 4 arquivos simples.

### Permissões liberadas (`.claude/settings.local.json`)

Em `/home/was/projetos/.claude/settings.local.json`. Liberado por padrão: rbenv, bundle, bin/rails, bin/rubocop, bin/brakeman, git, postgres CLI, Edit/Write em `~/projetos/**`.

---

## Roadmap atual (prioridade decrescente)

1. **Specs críticos da auth** — setup RSpec/SimpleCov/DatabaseCleaner pronto e verde (smoke). Falta cobrir `Users::Register` (paths do Result + honeypot), `Sessions::SignIn` (5 caminhos), `TwoFactor::Verify` (TOTP + backup code), 1 system test ponta-a-ponta (signup → confirm → login → 2FA enroll → verify). **Bloqueador antes de deploy** (auth sem testes = CVE territory).
2. **Multi-tenancy** — model `Workspace`, `workspace_memberships`, scoping por `current_workspace` (concern), migrar todos os models CRM para `belongs_to :workspace`. Reviewer flagou como dívida em todos os controllers atuais.
3. **CRM real (kanban)** — relacionamentos `has_many` nos models, kanban Hotwire com Turbo Streams drag-and-drop em real-time.
4. **IA copiloto** — `app/services/ai/` com Claude API: lead scoring + draft de email contextual.
5. **Engine de escalação** — model `EscalationRule` + job recorrente Solid Queue + notificação (Slack/email).
6. **Deploy Kamal 2** em VPS Hetzner — config `force_ssl = true`, GIF da demo no README, link público.

## Dívidas conhecidas (do reviewer, não-bloqueantes pra portfólio mas devem ser endereçadas)

- `Sessions::SignIn` 16 linhas no `call` — separar `requires_otp?` / `track_failure` em helpers privados.
- UX `:locked`/`:unconfirmed` mostra mensagem genérica de credenciais — considerar redirecionar `:unconfirmed` pro `new_confirmation_path`.
- `consume_backup_code` faz bcrypt em loop até 8x = ~800ms se TODOS errados (rate-limited por sessão, OK). Considerar SHA256 — backup codes têm 32 bits de entropia, bcrypt é overkill.
- `AuthEvents::Record` enfileira síncronamente (PG via Solid Queue). Se queue indisponível, derruba o request. Envolver em rescue `ActiveRecord::ConnectionTimeoutError, Deadlocked` pra fail-soft.
- `Pwned` síncrono dentro de validação. Considerar mover pra job pós-cadastro ou cachear hash prefixado por 1h.
- `start_new_session_for` falta `reset_session` (defense-in-depth contra session fixation).
- `PasswordsMailer.reset` view em inglês — trazer pra pt-BR.
- `AuthEvent` purging — sem job de retenção. Tabela cresce sem limite em prod.
- `honeypot_controller.js` tem stub vazio — implementar timing-check ou remover.
- `auth_events.user_id` FK sem `on_delete: :nullify` no DB-level (model usa `dependent: :nullify`, mas defesa-em-profundidade).
- Pattern duplicado `rate_limit ... with: -> { redirect_to X, alert: Y }` em 6 controllers — extrair concern `RateLimitedAuth` quando virar dor.

---

## Truques operacionais (úteis pra próxima sessão)

### Editar credentials sem EDITOR interativo
`bin/rails credentials:edit` abre um editor interativo. Em ambiente headless (CI, sandbox, agent), use o truque do `cp`:

```bash
cat > /tmp/cred.yml <<'EOF'
active_record_encryption:
  primary_key: ...
  deterministic_key: ...
  key_derivation_salt: ...
EOF

EDITOR='cp /tmp/cred.yml' bin/rails credentials:edit -e development
```

O Rails invoca `$EDITOR <tmpfile>`. Como `cp source dest` aceita 2 args, o tmpfile vira destino e nosso source vira o conteúdo final. Funciona com qualquer env (`development`, `test`, `production`).

### Tailwind v4 + Propshaft — quando classes não aparecem
1. `bin/rails tailwindcss:build` — rebuild manual.
2. Confirme o hash do CSS no HTML mudou (`/assets/tailwind-<hash>.css`).
3. Se `bin/dev` foi rodado e o `css.1` morreu (acontece em WSL), suba só `bin/rails server` e rode build manual quando adicionar classes.

### Matar server pendurado
```bash
[ -f tmp/pids/server.pid ] && kill $(cat tmp/pids/server.pid)
rm -f tmp/pids/server.pid
```

## Knowledge base externo

Além deste arquivo, contexto persistente do **usuário** (não do projeto) vive em `~/.claude/projects/-home-was-projetos/memory/MEMORY.md` — Claude Code carrega automaticamente. Contém:
- `user_role.md` — dev Rails 8, pt-BR
- `project_job_hunt_2026.md` — rescisão junho/2026, busca ativa vaga Rails
- `project_pipelinehq_decisions.md` — stack/auth/UI/RSpec travados aqui
- `feedback_senior_design_first.md` — desenhar arquitetura + edge cases ANTES de codar em features ≥ moderadas

ADRs do projeto em `docs/adr/0001-auth-nativa-rails-8.md` e `0002-camadas-hardening-auth.md`.
Posts LinkedIn em `posts/01-04-*.md`.

## Lições aprendidas

(Coordinator atualiza ao fim de cada feature.)

### Feature: Auth hardening (2026-06-18)
- **strong_migrations + tabela vazia**: a gem não diferencia tamanho de tabela. Mesmo em tabela nova/vazia, `add_index` sem `algorithm: :concurrently` é bloqueado. Padrão correto: **migration separada só pra índices** com `disable_ddl_transaction!`. Ensina o padrão correto e mantém CI verde.
- **`encrypts` + array column do PG não combinam**: `encrypts :otp_backup_codes` em `string[]` falha com "Unexpected array element" porque AR encryption converte pra string serializada. Solução: se já é bcrypt-hashed (one-way), AR encryption é redundante — remover.
- **`Rack::Attack.cache.store = Rails.cache`** > hardcode `SolidCache::Store.new`. Em dev vira MemoryStore, em prod vira Solid Cache. Universal, sem `uninitialized constant` no boot.
- **Token assinado via `generate_token_for`** (Rails 7+) é > coluna `confirmation_token` no DB: zero migration, zero index, expiração embutida no token.
- **Tailwind v4 dark mode por classe**: `@custom-variant dark (&:where(.dark, .dark *))` em `application.css`. Sem isso, `dark:` segue `prefers-color-scheme` do browser (media query) e usuário não controla. Combine com anti-flash inline script no `<head>` que lê `localStorage["theme"]` e aplica classe `dark` no `<html>` antes do CSS carregar.
- **Tailwind build com Propshaft**: depois de adicionar classes novas, rode `bin/rails tailwindcss:build` antes do server. `bin/dev` em ambiente WSL/sandbox às vezes derruba o watcher; o build explícito é mais previsível.
- **R3 (ViewComponent) compensa antes de 3 contextos**: 8 views com o mesmo input Tailwind viraram 8 chamadas declarativas + 1 fonte de verdade. Mudança de design = 1 edit em vez de 8. `AuthShellComponent` foi extraído na 6ª duplicação porque o padrão wrapper-centralizador-vertical era óbvio.
- **Hub-and-spoke real**: paralelizar 3 engineers (backend A + backend B + frontend) na mesma onda funciona quando o coordinator pré-acorda assinaturas de service (`Sessions::SignIn.call(email_address:, password:, request:) -> Result(:signed_in|:requires_otp|:invalid_credentials|:locked|:unconfirmed)`). Cada engineer escreve sem ver o outro e o produto encaixa.
- **Reviewer ortodoxo** (não passa a mão) bloqueou no `# frozen_string_literal: true` faltando em `application_controller.rb` e `current.rb` — coisa que outro reviewer "soft" ignoraria. Disciplina paga depois.
- **Centralização vertical**: `mx-auto max-w-sm` só centraliza horizontal. Pra V+H precisa de `flex min-h-screen items-center justify-center`. Casa típica de auth — virou `AuthShellComponent`.
- **Sempre `Rails.env.production?` em `cookies.signed.permanent`**: `secure: true` sempre quebra dev (HTTP). `secure: Rails.env.production?` é o padrão.

### Feature: RSpec + SimpleCov + pt-BR + profiler dev (2026-06-18)
- **SimpleCov tem que carregar ANTES do Rails**: no topo absoluto de `spec_helper.rb`, antes de qualquer `require`. `.rspec` com `--require spec_helper` garante ordem; se carregar dentro de `rails_helper.rb`, perde ~80% do código (autoloaded depois do start).
- **Stub global de `Passwords::BreachCheck` em `spec/support/passwords.rb`** elimina rede HIBP em toda factory `:user`. Production code (validator + service) intocado — princípio "test isolation, not production patching". Dívida: ao escrever o spec do próprio `BreachCheck`, scopar o stub por metadata pra não auto-testar o mock.
- **Shoulda Matchers só injeta DSL em groups `type: :model`** — smoke spec genérico (`describe "X"`) não tem `validate_presence_of`. Conclusão: smoke spec testa config; matchers vão pros model specs onde o tipo é inferível.
- **`config.use_transactional_fixtures = false` + DatabaseCleaner com strategy condicional** (transaction default, truncation pra `js:` ou `type: :system`) é o padrão correto pra Rails 8 + Capybara/Selenium. Transactional fixtures sozinhas vazam dados entre threads do Capybara em system specs.
- **rails-i18n + `config.i18n.default_locale = :"pt-BR"`** zera o trabalho manual de traduzir Active Record errors, helpers de data, e number formatting. AR/validations falavam inglês em flash messages antes; agora respeitam locale.
- **Selenium Manager nativo no Rails 8** = `selenium-webdriver` sem gem `webdrivers`. Driver baixa automático no primeiro `headless_chrome` request. Menos gem, menos manutenção.
- **rack-mini-profiler com FileStore em `tmp/miniprofiler`** evita dependência de Redis em dev. Badge no top-left mostra SQL + render time por request — fica o sinal visual constante de regressão de performance.
