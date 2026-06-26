# PipelineHQ

PipelineHQ é um CRM B2B multi-tenant em Rails 8.1.3 — pipeline de vendas no estilo Pipedrive/HubSpot, construído como projeto de portfólio. O foco é mostrar Rails 8 moderno (Solid Queue/Cache/Cable, Hotwire, Tailwind v4, auth nativa) usado com decisões deliberadas e segurança real, não receita pronta.

O projeto existe pra explorar uma pergunta concreta: "como arquitetar um SaaS em Rails 8 hoje?". Cada decisão tem um ADR em `docs/adr/`, cada camada de auth é um capítulo demonstrável, e tudo roda em Postgres — sem Redis, sem Sidekiq, sem Devise.

![Ruby 4.0.5](https://img.shields.io/badge/ruby-4.0.5-CC342D)
![Rails 8.1.3](https://img.shields.io/badge/rails-8.1.3-CC0000)
![License MIT](https://img.shields.io/badge/license-MIT-green)

## CI

Cada PR roda automaticamente: `brakeman`, `bundler-audit`, `importmap audit` e `rubocop`. A suite RSpec completa é opt-in via label: adicione **`CI:full`** ao PR para disparar `bundle exec rspec` com Postgres como service container. Push em `main` sempre roda a suite completa.

## Status

Em construção (junho/2026). Auth completa com 10 camadas de hardening; CRM em fase scaffold (Account, Contact, Stage, Deal, Activity gerados, relacionamentos pendentes).

## Stack

- Ruby 4.0.5 (via rbenv)
- Rails 8.1.3
- PostgreSQL (host único, sem extensões além das default)
- Tailwind CSS v4 via `tailwindcss-rails`
- Hotwire (Turbo + Stimulus)
- Solid Queue / Solid Cache / Solid Cable — toda a infra assíncrona em PG
- Propshaft (asset pipeline) + Importmap (sem bundler JS)
- Kamal 2 (deploy)
- Rubocop omakase, Brakeman, bundler-audit

**Não usa:** Redis, Sidekiq, Devise, React, Webpack, Node em produção.

## O que tem hoje

**Auth nativa Rails 8 estendida com 10 camadas de hardening** (ver ADR 0002):

1. Email confirmation por token assinado (`generate_token_for(:email_confirmation)`, sem coluna no DB).
2. Account lockout — 5 falhas em 15 minutos.
3. Rate limit cross-process via `rack-attack` em cima do `Rails.cache` (Solid Cache em prod).
4. Validador de senha forte (12+ chars, complexidade) + checagem opcional na Pwned Passwords API com fail-open.
5. 2FA TOTP via `rotp` + QR code via `rqrcode`. Secret encrypted via Active Record Encryption.
6. 8 backup codes single-use, armazenados com bcrypt.
7. UI de sessões ativas em `/settings/sessions` — revoke individual e "revoke all others".
8. Sudo mode — re-autenticação por password recente (≤15min) para ações sensíveis.
9. Audit log assíncrono em `auth_events` via Solid Queue, com GIN index em `metadata` jsonb.
10. Honeypot anti-bot no signup — campo invisível que retorna 200 OK fake se preenchido.

Login flow testado ponta-a-ponta com user de seed. **Zero gem de auth no Gemfile** (sem Devise, sem Sorcery, sem Rodauth).

**Scaffolds CRM iniciais:** `Account`, `Contact`, `Stage`, `Deal`, `Activity` gerados pelo Rails. Relacionamentos `has_many`, scoping multi-tenant por `workspace_id` e policies Pundit virão nos próximos PRs.

## Como rodar local

```bash
# Pré-requisitos
rbenv install 4.0.5 && rbenv local 4.0.5
# Postgres rodando em localhost:5432, user=postgres password=postgres

bundle install
bin/rails db:create db:migrate db:seed
bin/rails tailwindcss:build
bin/rails server

# Acesse http://localhost:3000
# Login: demo@pipelinehq.test / DemoUser!2026PipelineHQ
```

Pra rodar Rails + Tailwind watcher em paralelo:

```bash
bin/dev
```

Pra rodar o worker do Solid Queue em foreground (necessário pra audit log assíncrono e mailers):

```bash
bin/jobs
```

## Multi-tenancy

Isolamento por **row-level scoping com `workspace_id`** em toda tabela CRM. User pertence a 1+ `Workspace` via `WorkspaceMembership` com role enum (`owner / admin / member / viewer`). Workspace ativo persiste em `User.current_workspace_id` e em `session[:current_workspace_id]` para switching mid-session.

Defesa em profundidade em 3 camadas:

1. **Schema**: `workspace_id NOT NULL` + FK em `accounts/contacts/stages/deals/activities`.
2. **Scoping**: todo controller CRM usa `current_workspace.X.find(params[:id])` — nunca `X.find(params[:id])` solto.
3. **Pundit**: `ApplicationPolicy` base checa `record.workspace_id == Current.workspace.id` em toda action, além das regras de role.

Onboarding: `Users::Register` cria 1 workspace default no signup. Switching: dropdown no header (`WorkspaceSwitcherComponent`) com full reload pra evitar Turbo frames cacheados.

Trade-offs e alternativas (schema-per-tenant, CanCanCan, ActionPolicy) em [ADR 0004](docs/adr/0004-multi-tenancy-row-level-scoping-pundit.md).

## Domain audit

Eventos de domínio (criação/edição/destruição de Account/Contact/Stage/Deal/Activity + lifecycle de Workspace) são registrados em `domain_events` via service `DomainEvents::Record`, async via Solid Queue (mesma defesa em profundidade do `AuthEvent` de auth).

- Hooks centralizados via concern `RecordsDomainEvents` nos 5 controllers CRM
- Workspace lifecycle via chamada explícita em `Workspaces::Create` + `WorkspacesController#update`
- `kind` validado contra constante frozen `DomainEvent::KINDS` (21 entries)
- `metadata` jsonb com índice GIN para queries operacionais
- Leitura via `GET /domain_events` com filtro `?kind=` + paginação

Por que async, sem callbacks AR, sem PaperTrail, polimórfico vs FKs tipadas: [ADR 0005](docs/adr/0005-domain-events-audit-strategy.md).

## Decisões de arquitetura

ADRs vivem em `docs/adr/`:

- [ADR 0001 — Auth nativa do Rails 8 em vez de Devise](docs/adr/0001-auth-nativa-rails-8.md)
- [ADR 0002 — 10 camadas de hardening sobre a auth nativa](docs/adr/0002-camadas-hardening-auth.md)
- [ADR 0003 — Deploy via Kamal 2 em Oracle Cloud Always Free (ARM)](docs/adr/0003-deploy-kamal-oracle-arm.md)
- [ADR 0004 — Multi-tenancy via row-level scoping + Pundit](docs/adr/0004-multi-tenancy-row-level-scoping-pundit.md)
- [ADR 0005 — Domain events audit strategy](docs/adr/0005-domain-events-audit-strategy.md)

Novas decisões transversais (engine de escalação, IA copiloto) entram como ADRs incrementais antes da implementação.

## Roadmap

- Multi-tenancy por `workspace_id` (concern `CurrentWorkspace`, scoping em todos os controllers).
- Pipeline kanban com Turbo Streams + Stimulus para drag-and-drop entre stages.
- Engine de escalação — `EscalationRule` + job recorrente em Solid Queue.
- IA copiloto em `app/services/ai/` — lead scoring e draft de email via Claude API.
- Framework de testes (Minitest omakase) + cobertura mínima por feature (regra 29).
- Deploy Kamal 2 em VPS único, sem orquestrador externo.

## Estrutura de diretórios

```
app/
  controllers/     # finos por design (regra 1)
  models/          # User, Session, AuthEvent, Account, Contact, Deal, ...
  services/auth/   # Result.success/failure, sem callback de side effect
  views/           # Tailwind v4 + Hotwire partials
config/
  initializers/    # rack_attack.rb, etc.
db/migrate/        # migrations versionadas; strong_migrations virá no roadmap
docs/adr/          # decisões arquiteturais
posts/             # rascunhos de comunicação do portfólio
```

Detalhe completo da convenção (Service Object, Query Object, ViewComponent, Form Object) em `CLAUDE.md`.

## Licença

MIT (placeholder — arquivo `LICENSE` será adicionado antes da publicação pública).
