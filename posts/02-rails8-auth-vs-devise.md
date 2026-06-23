# Por que escolhi auth nativa do Rails 8 em vez de Devise

Continuando a série sobre o PipelineHQ, vou aprofundar a decisão que mais gera "por que?" em conversa técnica: trocar Devise por auth nativa do Rails 8.

**O que o gerador nativo entrega.** Desde o Rails 8.0 (set/2024), `bin/rails generate authentication` cria `User` com `has_secure_password`, model `Session` DB-backed (cada sessão é uma row, sem cookie store tradicional), controllers de login/logout/reset, mailer básico e a macro `rate_limit` no `ActionController::Base`. Tudo em código gerado dentro do `app/`, sem engine montada.

**Onde a auth nativa entrega valor vs Devise:**

- **Zero gem extra no componente mais crítico.** A superfície de ataque é o código que está no seu app — nada de "depender que a versão X corrigiu o CVE Z em tempo".
- **Controle total do fluxo.** Customizar é editar arquivo, não dobrar a API de uma engine.
- **Session DB-backed por padrão** — revoke individual, lista de sessões ativas, sudo mode viram coluna numa tabela que você lê com SQL normal. Em Devise puro, sessões vivem no cookie store; "deslogar todas as sessões" não é trivial.
- **Sinaliza fluência em Rails 8 moderno** quando isso é relevante (portfólio, entrevista, decisão de equipe).

**Onde Devise ainda ganha:**

- **`Confirmable`, `Trackable`, `Recoverable`, `Lockable` prontos.** Ativa o módulo no model e funciona. Na nativa, cada um vira código próprio.
- **OmniAuth integrado.** Login com Google/GitHub/Microsoft tem caminho batido. Na nativa, você junta provider gem + callback controller próprio. Funciona, mas é trabalho.
- **15 anos de battle-testing.** Auth feita à mão depende de testes próprios sólidos — não dá pra terceirizar essa confiança.

**Veredito (que não é "Devise tá morto"):**

Use Devise quando o time é pequeno, o produto não tem requisito de auth diferenciado, e você precisa enviar autenticação production-grade na primeira semana. É a escolha racional pra 80% dos casos.

Use auth nativa quando o produto **tem** requisito de auth diferenciado (multi-tenant com SSO custom, 2FA obrigatório, audit log fino, sessões revogáveis com UI), o time vai manter o código a longo prazo, e você prefere pagar o custo de implementar pra ter visibilidade total em troca.

No PipelineHQ a escolha foi a segunda — porque é um projeto de portfólio e o ponto é justamente mostrar essa leitura. Em produto comercial com prazo apertado, eu provavelmente usaria Devise.

ADR completo com alternativas consideradas (Devise + Devise-Security, Rodauth) em `<repo-url>`.
