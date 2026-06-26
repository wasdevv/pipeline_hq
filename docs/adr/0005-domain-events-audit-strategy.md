# 0005 — Domain events audit strategy

- Status: Accepted
- Data: 2026-06-24

## Contexto

PR 1 (foundation + policies) entregou multi-tenancy completo: `Workspace`, `WorkspaceMembership`, scoping, Pundit. A tabela `domain_events` já entrou no schema do PR 1a (skeleton only — sem writes). Faltava o **runtime de audit**: registrar quem fez o quê em qual workspace, de forma observável e durável.

Restrições e premissas:

- Stack Postgres single-DB + Solid Queue (sem Redis, sem Kafka, sem orquestrador externo).
- Audit deve ser **assíncrono** (não pode derrubar request da UI).
- Audit deve sobreviver a falha de DB transitória (mesma dívida do `AuthEvent`).
- Audit deve cobrir os 5 scaffolds CRM + lifecycle de `Workspace` (created, updated, switched no futuro PR 3).
- Não há features de timeline/dashboard ricas ainda — escopo é capturar eventos, índices certos, leitura básica via lista paginada.
- Regra #11 do projeto: services retornam `Result.success/failure`. Audit não muda o Result — efeito colateral.
- Regra #18 do projeto: side effects externos via Service Object, não AR callbacks.

## Decisão

**Writes via service `DomainEvents::Record`**, async via Solid Queue, **chamados por hooks de controller** (concern `RecordsDomainEvents`) para os 5 scaffolds CRM + chamada explícita dentro de services (`Workspaces::Create`, `WorkspacesController#update`).

### Modelo de evento

`DomainEvent` carrega:

- `kind`: string limitada à constante `DomainEvent::KINDS` frozen (21 entries: `workspace.*`, `membership.*`, e `<resource>.{created,updated,destroyed}` para os 5 CRM).
- `workspace_id`: NOT NULL — todo audit pertence a 1 workspace.
- `actor_id`: nullable — eventos de sistema (ex: futuro job de import) podem não ter actor.
- `subject_type` + `subject_id`: polimórfico opcional — eventos `workspace.created` não têm subject; eventos CRM sempre têm.
- `metadata` jsonb — payload flexível, índice GIN para queries operacionais.

### Pipeline

```
Controller action (POST/PATCH/DELETE)
   └─> after_action :record_domain_event (concern, only se audit_eligible?)
       └─> DomainEvents::Record.call(kind:, workspace:, actor:, subject:, metadata:)
           └─> DomainEventJob.perform_later(kind:, workspace_id:, actor_id:, subject_type:, subject_id:, metadata:)
               └─> Solid Queue worker
                   └─> DomainEvent.create!(...)
                       (rescue RecordInvalid, ConnectionTimeoutError → log + drop)
                       (discard_on DeserializationError)
```

### Hooks

- `RecordsDomainEvents` concern em `app/controllers/concerns/` — `after_action :record_domain_event, only: %i[create update destroy], if: :audit_eligible?`. Métodos hookáveis: `audit_subject`, `audit_workspace`, `audit_kind`, `audit_metadata`.
- 5 scaffolds CRM (accounts/contacts/stages/deals/activities) incluem o concern. `audit_kind` derivado automaticamente de `controller_name + action_name`.
- `WorkspacesController` inclui o concern mas precisa de `skip_after_action :record_domain_event` + re-register só pra `:update` (controller não tem `destroy`; `:create` é coberto pelo service `Workspaces::Create` chamando `DomainEvents::Record` direto na transaction).

### Leitura

- `DomainEventsController#index` (read-only) — `policy_scope(DomainEvent).recent.includes(:actor, :subject).limit(50).offset(...)`.
- `DomainEventPolicy::Scope` filtra por `Current.workspace.id`.
- Filtro opcional `?kind=<kind>` validado contra `KINDS`.

## Consequências

### Boas

- **Audit não derruba request**: Solid Queue absorve falha. Mesmo se DB cair entre enqueue e flush, Solid Queue persiste em PG (mesma transactional integridade).
- **Tenant scoping garantido por defesa em profundidade**: `workspace_id NOT NULL` no schema, `Current.workspace` no service, `policy_scope` no controller. Atacante precisa quebrar as 3 camadas.
- **Hooks centralizados via concern** — 5 controllers, 1 lugar pra mudar comportamento (R7). Pattern consistente com `WorkspaceScoped`.
- **`KINDS` frozen** evita kind inventado em runtime (validate :inclusion) — string typo vira erro de teste, não bug silencioso em prod.
- **`subject` polimórfico opcional** acomoda eventos sem subject natural (`workspace.created`) sem precisar de tabela separada por tipo.
- **`metadata` jsonb com GIN** permite queries operacionais ad-hoc no futuro (`WHERE metadata @> '{"reason": "bulk_import"}'`).
- **Reuse do pattern AuthEvent**: 95% estrutural igual. Lições aprendidas (kind frozen, async via Solid Queue, rescue de connection timeout) absorvidas sem retrabalho.

### Ruins / trade-offs

- **Eventual consistency**: leitor pode não ver evento que acabou de ser disparado se o worker estiver atrasado. Aceitável — audit não é caminho hot de produto.
- **Sem subject FK constraint** (polimórfico): se `Account` for hard-deleted, `subject_id` aponta pra nada. Mitigado por `dependent: :nullify` no `has_many :domain_events, as: :subject` dos 5 models CRM (deletion clears subject_type+subject_id).
- **Job rescues swallow errors**: `RecordInvalid` + `ConnectionTimeoutError` viram log warn + drop. Aceito — audit não pode bloquear request. Dívida: alerting via logging structured/Sentry no futuro.
- **`WorkspacesController#update` exige skip_after_action ginástica**: porque o controller não tem `destroy` mas o concern tenta registrá-lo. Solução cirúrgica funciona; alternativa de inferir actions dinamicamente no concern foi rejeitada como over-engineering pra 1 caso. Aceitar e documentar.
- **No batching**: cada action emite 1 job. Pra cenário de bulk-import (PR futuro), considerar `DomainEvents::RecordBatch.call(events:)` que enfileira 1 job com array.

### Alternativas consideradas

- **AR callbacks** (`after_commit :record_event`): rejeitado pelo R18 (side effect externo = service, não callback). Acopla domínio a infra de audit.
- **PaperTrail / Audited gem**: rejeitado por (a) adicionar 1 gem com versionamento de cada attribute change (overkill pro escopo), (b) acoplamento ao AR callback, (c) tabela própria com schema diferente — perderia o jsonb metadata flexível.
- **Sync writes** (`DomainEvent.create!` direto no service): rejeitado pra audit não bloquear request. Solid Queue absorve.
- **Enum integer pra `kind`** em vez de string Array frozen: rejeitado por (a) migrations por nova kind, (b) log/grep menos legível.
- **`subject` com 5 FKs tipadas** em vez de polimórfico: rejeitado por (a) overhead de schema (5 colunas nullable + 5 FKs constraints), (b) query por subject_type fica mais fácil polimórfico (`WHERE subject_type = 'Deal'`).
- **CQRS / event sourcing completo**: rejeitado — escopo é audit observability, não rebuild de estado a partir de events.

## Plano de execução absorvido

PR 2 entrega:
- `DomainEvents::Record` service + `DomainEventJob` (Solid Queue, queue `:low`)
- `DomainEvent::KINDS` frozen (21 entries)
- `RecordsDomainEvents` concern em 6 controllers (5 CRM + WorkspacesController)
- Hook explícito em `Workspaces::Create`
- `DomainEventsController#index` + `DomainEventPolicy` + view simples
- 49 examples novos, 100% line coverage

Próximas iterações (fora deste PR):
- PR 3: convites por email (gera `membership.added`)
- Workspace member management (gera `membership.role_changed`, `membership.removed`)
- Retention/purge job para `domain_events` antigos
- Timeline UI rica (agrupamento por dia, infinite scroll)
- Webhook outbound dos events
