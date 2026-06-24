# 0003 — Deploy via Kamal 2 em Oracle Cloud Always Free (ARM)

- Status: Accepted
- Data: 2026-06-23

## Contexto

O PipelineHQ precisa de um link público pra recruiter abrir e validar o projeto. As restrições do projeto pesam na decisão:

- Sem custo recorrente forte (portfolio sem receita)
- Sem Redis, sem orquestrador externo (Solid Queue/Cache/Cable no Postgres)
- Single-host é suficiente — não há requisito de HA
- Stack do projeto é Rails 8 + Postgres, deploy via Docker
- Latência baixa pro recruiter brasileiro é desejável
- Sinal técnico do deploy faz parte do portfólio: deployar do jeito "Kamal + VPS" alinha com a narrativa "ortodoxia Rails 8 moderna" que o resto do projeto sustenta

## Decisão

Deploy via **Kamal 2** em uma VM **Oracle Cloud Always Free** (Ampere A1, ARM64) na região São Paulo, com:

- Postgres 16 em accessory container no mesmo host (sem managed DB pago)
- kamal-proxy (sucessor do Traefik no Kamal 2) terminando SSL via Let's Encrypt automático
- Imagem buildada localmente como `linux/arm64`, publicada em **GitHub Container Registry** (`ghcr.io`)
- Secrets vindas de ENV local + `gh auth token` (sem cofre externo no primeiro round)
- Solid Queue rodando dentro do mesmo processo Puma (`SOLID_QUEUE_IN_PUMA: true`)

## Consequências

### Boas

- **Custo direto: R$0.** Oracle Always Free dá 4 OCPUs Ampere A1 + 24GB RAM + 200GB storage permanentemente, na região São Paulo. PipelineHQ usa fração disso.
- **Latência baixa pro Brasil** (~30ms) — DC em São Paulo, recruiter abre o link e a página responde rápido.
- **Sinal técnico forte** — Kamal 2 é o deploy nativo do Rails 8 moderno. Deployar com `bin/kamal deploy` num VPS próprio mostra leitura técnica que PaaS managed esconde.
- **Postgres em accessory container** mantém a coerência com "tudo no Docker, single-host, sem managed services" do resto da arquitetura.
- **GHCR free** pra imagens públicas, sem cobrança de pull/push.
- **Portabilidade total** — `config/deploy.yml` funciona em qualquer VPS com SSH + Docker. Se Oracle tirar o Always Free, é só trocar o IP no servers e re-deploy.

### Ruins / trade-offs

- **Capacidade ARM A1 em São Paulo às vezes esgota.** Oracle libera quotas por demanda regional; pode levar dias/semanas pra conseguir criar a VM. Mitigação: retry até pegar, ou fallback pra US-East / EU.
- **UI da Oracle Cloud é antiquada.** Setup inicial é mais doloroso que DigitalOcean/Hetzner. Documentação pro time futuro precisa ser explícita.
- **Always Free pode ser descontinuado.** Oracle reserva direito de mudar termos. Risco aceito — fácil migrar pra outro VPS.
- **Self-managed Postgres.** Sem backup automático managed, sem failover. Mitigação: snapshot manual da VM via Oracle console + dump diário pra storage local antes do MVP virar produto sério.
- **iptables Ubuntu default na Oracle bloqueia entrada.** Gotcha clássica — precisa `iptables -I INPUT -p tcp --dport 80 -j ACCEPT` (e 443) além da security list do VCN.
- **Cross-compile ARM64 do dev machine x86** exige `docker buildx` com QEMU. Build mais lento que nativo. Aceitável pra deploys de portfolio (não é hot path de CI).

### Alternativas consideradas

- **Railway:** PaaS managed, git push to deploy. Rejeitado porque (a) preço real estimado ~$21/mês excede o que faz sentido pra portfolio sem receita, (b) data center mais próximo é US-East (~120ms BR), (c) PaaS esconde a infra — não casa com a narrativa "Rails 8 ortodoxo" do resto do projeto.
- **DigitalOcean SP (~R$70/mês):** DX excelente, dashboard top, sem trava. Rejeitado por custo recorrente — Oracle Always Free entrega capacidade similar de graça.
- **Hostinger BR KVM 2 (~R$23/mês com trava 24m):** Hardware top (8GB RAM), preço imbatível. Rejeitado porque o pagamento upfront R$552 + trava contratual não vale pra portfolio antes de validar que vai ficar no ar 24+ meses.
- **Hetzner CAX11 (~R$25/mês, sem trava):** Mais barato sem trava entre os pagos. Rejeitado porque DC em Helsinki/Falkenstein adiciona ~200ms de latência pro Brasil — recruiter brasileiro percebe.
- **PC local + Cloudflare Tunnel:** Aparentemente grátis, mas custo de energia (R$30-80/mês desktop ligado 24/7) + risco de uptime quando o PC dorme/reboota torna inviável pra portfolio sério.
- **Heroku eco/basic ($5/mês):** Sleep agressivo no eco, basic ($7) sem free DB. PaaS clássico mas igual ao Railway esconde infra.
- **Render free tier:** App sleep após 15min sem requests — fatal pra portfolio que recruiter abre uma vez.
- **Fly.io:** boa opção, sem DC BR, free tier limitado. Equivalente ao Hetzner em latência.

## Plano de execução

1. **Setup Oracle account** (~30-60min, gargalo de provisionamento humano)
2. **Criar VM ARM A1.Flex** na região SP (pode precisar retry por capacidade)
3. **Configurar VCN + security list** pra portas 22 / 80 / 443
4. **Ajustar iptables Ubuntu** dentro da VM pra liberar entrada
5. **Instalar Docker** na VM (Kamal pode fazer no `kamal setup`)
6. **Setup DNS** apontando o domínio pro IP da VM
7. **Editar `config/deploy.yml`** substituindo `<ORACLE_VM_PUBLIC_IP>` e `<YOUR_DOMAIN>`
8. **Exportar secrets** (`PIPELINE_HQ_POSTGRES_PASSWORD`, AR encryption keys) no shell
9. **`bin/kamal setup`** — provisiona Docker, sobe Postgres accessory, deploya web
10. **`bin/kamal app exec "bin/rails db:prepare"`** — cria schemas iniciais
11. **`bin/kamal app exec "bin/rails db:seed"`** — opcional, seed do user demo
12. **Validar:** abrir `https://<dominio>/up` (healthcheck) + `https://<dominio>/session/new` (login)
