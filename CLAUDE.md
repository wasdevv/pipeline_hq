# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

**PipelineHQ** é um CRM B2B multi-tenant em Ruby on Rails 8 — pipeline de vendas estilo Pipedrive/HubSpot, pensado como portfólio sênior. Fase inicial: scaffolds gerados, sem autenticação, sem multi-tenancy, sem framework de testes.

## Stack

- **Ruby 4.0.5** via rbenv (`.ruby-version` na raiz).
- **Rails 8.1.3**.
- **PostgreSQL** local — `host=localhost user=postgres password=postgres` em dev/test.
- **Tailwind CSS v4** via `tailwindcss-rails`.
- **Propshaft** + **Importmap** (sem bundler JS).
- **Hotwire**: Turbo + Stimulus.
- **Solid Queue / Cache / Cable** — tudo no PG, sem Redis.
- **Kamal 2** (deploy).
- **Rubocop omakase**, **Brakeman**, **bundler-audit**.
- **Sem framework de testes ainda** — projeto criado com `--skip-test`. Decidir Minitest (default omakase) ou RSpec antes da próxima feature.

## Comandos

```bash
bin/dev              # Rails + Tailwind watcher (foreman)
bin/rails server
bin/rails console
bin/rails db:create db:migrate db:seed
bin/rails db:reset

# Geradores
bin/rails generate scaffold Lead account:references score:integer
bin/rails generate migration AddIndexToLeadsScore
bin/rails generate authentication      # auth nativa Rails 8

# Qualidade
bin/rubocop                # lint
bin/rubocop -a             # autocorrect seguro
bin/brakeman               # security scan
bin/bundler-audit          # CVEs em gems

# Jobs (Solid Queue)
bin/jobs                   # worker em foreground
```

## Arquitetura — estado atual

Models scaffoldados (sem relacionamentos `has_many` declarados ainda):

| Modelo | Campos principais | Pendência |
|---|---|---|
| `Account` | name, industry, website, notes | `has_many :contacts, :deals` |
| `Contact` | account_id, name, email, phone, role | OK |
| `Stage` | name, position, color | `has_many :deals`, unicidade de position por workspace |
| `Deal` | title, account_id, contact_id, stage_id, amount_cents, currency, expected_close_on, status | `has_many :activities`, money via composed_of |
| `Activity` | deal_id, kind, subject, body, occurred_at | OK |

**Decisões arquiteturais pendentes** (priorizar nessa ordem):

1. Framework de testes — Minitest ou RSpec.
2. Autenticação — `bin/rails generate authentication` (nativa). **Não Devise.**
3. Multi-tenancy — scoping por `workspace_id`. `current_workspace` em concern. **Não schema-per-tenant.**
4. Service Objects em `app/services/`, padrão `Class.call(args) -> Result`.
5. ViewComponent quando partial se repete em ≥2 contextos.
6. Engine de escalação — model `EscalationRule` + job recorrente Solid Queue.
7. IA — `app/services/ai/` com Claude API (lead scoring, draft de email).

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
23. Índice em tabela grande (>100k rows): `disable_ddl_transaction!` + `algorithm: :concurrently`.
24. Dinheiro: `amount_cents:integer` + `currency:string` + Money-Rails. `decimal` proibido para valores monetários.
25. Use `strong_migrations` pra catch automático de migration insegura em CI.

### Performance (26-28)
26. **Zero N+1** — `bullet` ativo em dev; toda listagem com `includes`/`preload`.
27. **Counter cache** pra contagem hot (`deals_count` em Account).
28. `find_each` / `in_batches` para coleções > 1000 registros.

### Testes & Segurança (29-30)
29. Cobertura mínima por feature: model (validações/scopes), service (cada caminho do Result), 1 system test ponta-a-ponta. Mock apenas em `app/services/ai/` e HTTP externo (WebMock/VCR).
30. Autorização explícita por ação — `current_user` autenticado não basta. Use Pundit ou policy class plain Ruby; scoping multi-tenant via `current_workspace`.

---

## Gems recomendadas

Já no projeto: Rails, pg, tailwindcss-rails, importmap-rails, turbo-rails, stimulus-rails, solid_queue/cache/cable, kamal, propshaft, rubocop-rails-omakase, brakeman, bundler-audit.

Adicionar conforme necessidade:

**Arquitetura / qualidade**
- `pundit` — autorização por policy class
- `view_component` — componentes UI reutilizáveis
- `pagy` — paginação rápida
- `strong_migrations` — bloqueia migrations inseguras
- `dry-monads` — `Result`/`Maybe` se quiser DSL pronto

**PostgreSQL**
- `pg_search` — full-text com tsvector
- `scenic` — materialized views versionadas
- `fx` — funções e triggers PG em migrations

**Domínio**
- `money-rails` — money types
- `paper_trail` ou `audited` — audit log
- `discard` — soft delete por flag

**Observabilidade**
- `lograge` — logs JSON estruturados
- `rack-attack` — rate limiting
- `marginalia` — origem da query como comentário SQL

**Dev**
- `bullet` — N+1 detection
- `annotaterb` — schema nos models
- `letter_opener` — abre email no navegador em dev
- `pry-rails` + `awesome_print`
- `factory_bot_rails` + `faker` (se RSpec)

---

## Workflow com subagents — Hub-and-Spoke

**Princípio:** o `coordinator` é o **hub**. **Subagents nunca chamam outros subagents** — só reportam ao coordinator, que decide o próximo passo. Conflito de output = coordinator resolve ou escala ao usuário.

### Roster

| Agent | Modelo | Função |
|---|---|---|
| `coordinator` | opus | Único que invoca outros. Decompõe, decide estratégia, agrega |
| `planner` | opus | Decompõe pedido vago em roadmap/milestones (vem antes do architect) |
| `architect` | opus | Design técnico (modelos, serviços, índices, trade-offs) |
| `rails-engineer` | sonnet | Implementa backend Rails |
| `frontend-engineer` | sonnet | Tailwind v4, Hotwire UI, ViewComponent, acessibilidade |
| `data-agent` | sonnet | Postgres avançado: índices, EXPLAIN, materialized views, seeds |
| `tester` | sonnet | Escreve e roda testes |
| `reviewer` | sonnet | Code review enforçando as 30 regras |
| `writer` | sonnet | README, ADR, CHANGELOG, post LinkedIn |
| `summariser` | haiku | Condensa output longo |

### Fluxo padrão

```
1. DECOMPOSE
   Coordinator lê CLAUDE.md, decompõe pedido em TaskCreate (uma task por subtarefa concreta).

2. ASSESS COMPLEXITY
   Trivial   (1 arquivo, sem decisão)            → single agent
   Normal    (2-5 arquivos, mesmo domínio)       → 2-3 agents em sequência
   Complexa  (transversal, ambíguo, novo escopo) → planner + agents em paralelo

3. STRATEGY
   Single:     rails-engineer (ou agente específico)
   Sequencial: architect → rails-engineer → tester → reviewer
   Paralela:   architect + frontend-engineer + data-agent simultâneos,
               depois merge → tester → reviewer

4. AGGREGATE (merge, rank, resolve conflicts)
   Coordinator recebe outputs. Se >2k tokens, passa pelo summariser antes de relayar
   ao próximo agente. Conflito = coordinator decide (cita regra) ou escala ao usuário.

5. CLOSE
   Reviewer aprova → writer atualiza CHANGELOG/PR description se aplicável →
   coordinator atualiza "Lições aprendidas" no CLAUDE.md.
```

### Saída fixa de todo subagent

Todo subagent (exceto coordinator) devolve ao coordinator no formato:

```
## Resumo
<1-3 linhas: o que foi entregue>

## Arquivos tocados
- path/x.rb
- path/y.erb

## Decisões/Trade-offs
- <bullets opcionais>

## Bloqueios / Próximo passo sugerido
<o que falta ou o que recomendar a seguir>
```

---

## Lições aprendidas

(Coordinator atualiza ao fim de cada feature.)

- _Nenhuma ainda — primeira feature em andamento._
