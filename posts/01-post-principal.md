# Rebuildei autenticação em Rails 8 sem Devise. Aqui vai o que aprendi.

Rails 8 trouxe um gerador nativo de autenticação. Em vez de cair no reflexo de mercado ("auth = Devise"), gastei algumas semanas explorando o gerador e construindo hardening em cima. O resultado virou a primeira fundação do PipelineHQ, um CRM B2B que estou montando como projeto de portfólio.

O gerador entrega o esqueleto: `User` com `has_secure_password`, `Session` DB-backed, password reset por token assinado e a macro `rate_limit` no controller. Nada além disso. Sem 2FA, sem lockout, sem confirmação de email, sem audit log. Em 2026, isso não passa em review de segurança de produto B2B.

A decisão foi usar o gerador como base e construir 10 camadas de hardening em código próprio: email confirmation via `generate_token_for(:email_confirmation)` (token assinado com expiração embutida, zero coluna nova no DB), lockout após 5 falhas em 15 minutos, rate limit cross-process com rack-attack apoiado em Solid Cache (sem Redis), validador de senha forte com checagem Pwned em fail-open, TOTP 2FA com ROTP + rqrcode, 8 backup codes bcrypt'd, UI de sessões ativas com revoke individual, sudo mode pra ações sensíveis, audit log assíncrono via Solid Queue e honeypot no signup.

Os trade-offs que valem nomear:

**Perdi Confirmable, Lockable, Recoverable e Omniauth do Devise.** Cada um virou código próprio pra manter. O ganho: o fluxo de auth inteiro vive em `app/controllers/sessions_controller.rb` e `app/services/auth/`, sem indireção via engine montada. Quando precisar entender por que uma sessão expirou, eu leio Ruby — não config de gem.

**Devise tem 15 anos de battle-testing.** Minha reimplementação tem semanas. Mitiguei com escopo fechado (10 camadas pré-definidas, não "vou improvisando") e testes obrigatórios por camada.

**Solid Cache como backing do rack-attack** dispensou Redis inteiro. Latência subjetivamente similar pro uso de contadores curtos; ganho operacional concreto: uma dependência a menos no Kamal, zero custo de Redis hospedado.

O que aprendi e vale mais que o código em si: (1) o `generate_token_for` do Rails 7+ resolve uma classe inteira de bug que era padrão em Devise — token vazado em log, token sem expiração, coluna esquecida sem index. Quando o token carrega o propósito assinado, você não tem essas opções de errar. (2) "Sem Redis" em Rails 8 deixou de ser exótico. Solid Queue/Cache/Cable cobrem o caso de uso de SaaS pequeno-médio sem cerimônia.

Repo em `<repo-url>` (em construção). Os dois ADRs fundacionais (auth nativa vs Devise; as 10 camadas) estão linkados no README — se for revisar, comece por lá.
