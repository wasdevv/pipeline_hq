# Rate limit cross-process sem Redis: Rails 8 + rack-attack

Quarto post da série PipelineHQ. Tema chato e que normalmente vira "ah, instala Redis": rate limit que funciona com múltiplos workers, sem dependência operacional nova.

**A dor antiga.** rack-attack precisa de um backing store compartilhado entre processos. Se cada worker Puma tem o contador na memória local, "5 tentativas em 15 minutos" vira "5 tentativas por worker" — 20 com 4 workers. Inútil. A solução padrão é Redis. Funciona, mas adiciona uma dependência operacional inteira (provisionamento, backup, monitoração, custo) pra um caso de uso que é só "contador com TTL".

**O que Rails 8 mudou.** Solid Queue, Solid Cache e Solid Cable trouxeram fila, cache e pub/sub no próprio Postgres. Em prod, `Rails.cache` aponta automaticamente pro Solid Cache. Em dev, MemoryStore.

A configuração inteira do rack-attack vira:

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.cache.store = Rails.cache
```

Uma linha. Em prod, Solid Cache via PG. Em dev, MemoryStore (suficiente, processo único).

**Throttles atuais no PipelineHQ:**

- 20 logins por IP a cada 5 minutos.
- 10 logins por email a cada 5 minutos (defesa contra password spray distribuído).
- 10 signups por IP a cada 5 minutos.
- 10 password-reset por IP a cada 5 minutos (defesa contra enumeration via email de reset).

Resposta padrão: 429 com `Retry-After`. Sem mensagem custom — atacante não precisa saber.

**O trade-off honesto.** Latência por incremento de contador em PG é maior que em Redis. Subjetivamente está na casa de poucos milissegundos, contra sub-milissegundo de Redis. Pra rate limit de endpoint de auth (que já tem bcrypt no caminho crítico custando 50-80ms), o delta é irrelevante. Pra endpoint hot de API tipo "200k req/s", o cálculo seria diferente — aí Redis ganha. Não é meu caso.

**O ganho operacional concreto:** uma linha no `Kamal.yml` a menos, uma dependência a menos pra atualizar, zero custo de Redis hospedado, zero "ah, o Redis morreu". Pra SaaS pequeno-médio, é o trade-off certo.

**Ortodoxia Rails 8 como princípio.** "Tudo em Postgres" deixou de ser exótico. Solid Queue cobre fila durável. Solid Cache cobre cache com TTL. Solid Cable cobre pub/sub pra ActionCable. Pra três dependências antes obrigatórias (Sidekiq+Redis, Memcached, Redis-pubsub), a resposta agora é "PG". Não é melhor em toda métrica — Redis ganha em latência pura — mas é melhor no agregado pra muita aplicação real.

Config completa do rack-attack + thresholds em `<repo-url>`.
