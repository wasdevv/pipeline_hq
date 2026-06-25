# 0004 — Multi-tenancy via row-level scoping + Pundit

- Status: Accepted
- Data: 2026-06-24

## Contexto

O PipelineHQ entra na fase CRM real. Com os scaffolds `Account/Contact/Stage/Deal/Activity` em pé mas sem isolamento entre usuários, qualquer user logado podia ler/editar dados de qualquer outro — violação direta da regra #20 do CLAUDE.md ("`current_workspace.deals.find(id)` — nunca `Deal.find(params[:id])`") e a #1 vulnerabilidade pra SaaS B2B.

Antes de qualquer feature nova de CRM (kanban, IA, escalação), o isolamento precisa estar resolvido. Refatorar depois custa reescrever cada controller + cada query + cada policy.

Restrições adicionais:

- Stack: Postgres single-DB, Rails 8, Solid Queue. Sem Redis, sem orquestrador externo.
- Portfolio de 1 autor — manutenção é custo direto. Schema simples vence sobre arquitetura sofisticada.
- Cobertura de testes obrigatória (regra #29).
- Cost cap dos agents LOOPS: 200k tokens/feature. Feature dividida em 2 PRs (foundation + audit) pra caber.

## Decisão

**Row-level scoping com `workspace_id` em toda tabela CRM**, autorização via **Pundit**, e estado de workspace ativo por usuário via **`Current.workspace`**.

Modelo de domínio:

- `Workspace` é o tenant. User pertence a 1+ workspace via `WorkspaceMembership` com role enum (`owner / admin / member / viewer`).
- `User.current_workspace_id` persiste o workspace ativo entre sessões.
- `session[:current_workspace_id]` é a overlay de switching mid-session.
- Toda tabela CRM ganha `workspace_id NOT NULL` + FK + índice composto `(workspace_id, ...)`.
- Todo controller CRM usa `current_workspace.X.find(params[:id])` — nunca `X.find(params[:id])` solto.
- `ApplicationPolicy` base com `scoped_to_workspace?` checando `record.workspace_id == Current.workspace.id` como defesa em profundidade.

## Consequências

### Boas

- **Defesa em profundidade real:** 3 camadas (`workspace_id` FK no schema, scoping no controller, Pundit checa `scoped_to_workspace?` no policy). Atacante precisaria furar as 3 pra leak data entre tenants.
- **Schema simples — Postgres único, sem mágica.** Migration `add_reference :accounts, :workspace, foreign_key: true` em 5 tabelas. Sem schema-per-tenant, sem partition routing, sem extension PG.
- **Pundit ortogonal à scoping.** Policy testa "esse user pode fazer essa ação?", scoping testa "esse user pode ver esse record?". Separação clara de responsabilidades.
- **`Current.workspace` é per-request** (ActiveSupport::CurrentAttributes), reseta automaticamente entre threads de request — mesmo padrão de `Current.user`/`Current.session` já em uso.
- **Roles enum simples** (4 níveis) cobrem 90% dos casos sem virar matriz combinatorial de permissões.
- **`Users::Register` cria workspace default** no signup — invariante "user sempre tem ≥ 1 workspace" garantida; UX limpa (sem onboarding extra de "crie seu primeiro workspace").
- **Backfill via rake task idempotente** (`workspace:backfill`) — re-runnable, anti-pattern de backfill em migration evitado (lição registrada no CLAUDE.md).

### Ruins / trade-offs

- **`workspace_id` em toda tabela CRM** é boilerplate eterno. Toda nova feature ganha esse campo. Aceitar.
- **Migration sequencial em 3 passos** (nullable → backfill → NOT NULL) é o caminho seguro (lição strong_migrations) mas verboso. 5 tabelas × 3 migrations + índices em migrations dedicadas = 12 migrations só pra schema. Tooling pode mascarar via `mr_strong_migrations` no futuro.
- **Pundit boilerplate em 5 controllers** — `authorize @record` em cada action é repetição. Vale aceitar até a 3ª duplicação real virar dor (regra #2). Concern `AuthorizesResource` fica como dívida explícita.
- **`Current.workspace` não cruza thread boundary do Solid Queue.** Jobs precisam receber `workspace_id` explícito como parâmetro (será aplicado no PR 2 quando `DomainEvents::Record` ficar assíncrono).
- **Switching mid-session pode mostrar dados em flight** (Turbo Frames cacheados do workspace anterior). Mitigação atual: full reload no switcher (`data: { turbo: false }` no link). Aceitável pro MVP.
- **Slug derivado de `name` (parameterize + suffix numérico)** é legível mas limita customização (user não pode escolher slug). Aceitável; futuro: adicionar campo opcional.

### Alternativas consideradas

- **Schema-per-tenant** (1 schema PG por workspace): isolamento mais forte, zero risco de cross-tenant leak por query mal escrita. Rejeitado porque: (a) migrations viram pesadelo operacional (rodar em N schemas a cada deploy); (b) backup/restore por tenant é complicado; (c) joins entre dados de workspaces (relatórios cross-tenant, admin views) ficam impossíveis sem `SET search_path` malabarismo; (d) overhead massivo pra portfolio de 1 autor.
- **CanCanCan em vez de Pundit:** mais expressivo, mas DSL própria que esconde lógica. Pundit é PORO (Plain Old Ruby Object) — debug é `binding.pry` direto. Mantém o princípio "explícito > mágico" do resto do projeto.
- **ActionPolicy:** mais moderno que Pundit, performance melhor em apps grandes. Rejeitado por adoção marginal no BR; Pundit tem mais documentação em pt-BR.
- **`current_workspace` helper em vez de `Current.workspace`:** menos consistente com o padrão `Current.user`/`Current.session` já em uso. Manter consistência interna vence.
- **Domain events writes no MESMO PR:** rejeitado por cost cap (feature teria passado de 200k tokens). Tabela `domain_events` entra com schema agora (zero custo), writes ficam pro PR 2.

## Plano de PRs

- **PR 1a — `feature/workspace-foundation`** (mergeado): schema + models + backfill + tests.
- **PR 1b — `feature/workspace-foundation-policies`** (este PR): `Current.workspace`, scoping concern, 7 Pundit policies, 5 controllers CRM reescritos, `Workspaces::Create/Switch`, `Users::Register` integration, switcher UI + views, ADR 0004, README seção.
- **PR 2 — `feature/domain-audit`**: `DomainEvents::Record` service + hooks nos services CRM + dashboard básico de audit.
- **PR 3 — `feature/workspace-invites`**: convites por email + accept flow.

## Bug de produção corrigido durante implementação

`WorkspaceSwitchesController#create` lia `params[:workspace_id]`, mas a rota é member action (`post :switch, on: :member`) e o param do Rails é `:id`. Resultado: `Workspace.find_by(id: nil)` → `Workspaces::Switch.call(user:, workspace: nil)` → `Result.failure(:not_found)` → switching nunca funcionava. Descoberto pelo tester probando o request spec real. Fix: `params[:id]`. Lição: nomes de params em member actions exigem cuidado em request specs.
