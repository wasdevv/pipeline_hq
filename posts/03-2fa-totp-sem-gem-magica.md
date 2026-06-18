# Como implementei 2FA TOTP sem gem mágica

Terceiro post da série PipelineHQ. Hoje: 2FA por TOTP, do zero, com gem-base mínima e sem `devise-two-factor`.

**O problema.** 2FA em produto B2B em 2026 é table-stakes. Credential stuffing é a classe de ataque mais comum pós-vazamento, e password única — por mais forte que seja — fecha um vetor só.

**A stack:**

- `rotp` — geração e verificação do TOTP (RFC 6238).
- `rqrcode` — renderização do QR code SVG inline.
- Active Record Encryption (built-in no Rails 7+) — encriptar o `otp_secret`.
- `bcrypt` (já no Gemfile via `has_secure_password`) — hash dos backup codes.

Cada peça resolve uma coisa e nada além.

**O fluxo em 5 passos:**

1. **Enroll** — `/settings/two_factor/new`. Gero `ROTP::Base32.random` e guardo em `User#otp_secret` (encrypted). Status: `otp_pending`.
2. **QR code** — renderizo o `otpauth://totp/...` como SVG via rqrcode. O secret também aparece em texto pra gestores de senha manuais.
3. **Confirm** — usuário digita o código de 6 dígitos. Bate → `otp_required_for_login = true` e geramos os backup codes.
4. **Backup codes** — 8 strings aleatórias (base32, 10 chars), exibidas uma única vez. Armazenadas com bcrypt cost 12 (~50-80ms por verificação — aceitável dado que backup code é uso pontual, não fluxo quente).
5. **Verify no login** — após password ok, se `otp_required_for_login`, redireciono pra `/sessions/otp`. Aceita TOTP de 6 dígitos OU backup code. Match positivo cria a sessão; backup code usado é marcado como consumido.

**Três decisões que valeram o tempo de pensar:**

**(a) Active Record Encryption no `otp_secret`.** Vazamento de dump de DB não pode dar ao atacante o segredo pra gerar TOTPs válidos. Rails 7+ traz isso built-in (`encrypts :otp_secret`) e a chave fica em `credentials.yml.enc`. Custo zero pra mim, ganho grande de defesa em profundidade.

**(b) Backup codes como `text[]` em PG + `update!` atômico.** Quando o usuário consome um código, faço bcrypt match in-memory contra cada elemento; achou match, removo do array e `user.update!(backup_codes: novo_array)`. Atômico via row-level lock implícito do PG. Não preciso de tabela `backup_codes` separada.

**(c) `drift_behind: 30` no ROTP.** Time skew acontece. Aceita o código da janela anterior (não da próxima), cobrindo 99% do skew real sem abrir janela maior de replay. Detalhe que evita ticket de "meu Authenticator não funciona".

**O que não fiz.** WebAuthn / Passkeys ficou pra fase 2. Passkey é o futuro e cobre uma classe de ataque que TOTP deixa aberta (phishing em tempo real). Mas implementar bem dobra o escopo. TOTP cobre o caso principal hoje; Passkey entra como ADR separado depois.

Código completo (model, services, controllers, views) em `<repo-url>`.
