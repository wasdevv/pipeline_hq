# frozen_string_literal: true

if Rails.env.development?
  user = User.find_or_initialize_by(email_address: "demo@pipelinehq.test")
  user.assign_attributes(
    name:                  "Demo User",
    password:              "DemoUser!2026PipelineHQ",
    password_confirmation: "DemoUser!2026PipelineHQ",
    confirmed_at:          Time.current
  )
  user.save!
  puts "Seeded demo@pipelinehq.test / DemoUser!2026PipelineHQ"

  workspace = user.current_workspace || Workspace.find_or_create_by!(slug: "demo") do |w|
    w.name = "Workspace Demo"
    w.owner = user
  end
  WorkspaceMembership.find_or_create_by!(workspace: workspace, user: user) { |m| m.role = :owner }
  user.update!(current_workspace: workspace) if user.current_workspace_id.nil?

  teammate = User.find_or_initialize_by(email_address: "ana@pipelinehq.test")
  teammate.assign_attributes(
    name:                  "Ana Ribeiro",
    password:              "AnaTeam!2026PipelineHQ",
    password_confirmation: "AnaTeam!2026PipelineHQ",
    confirmed_at:          Time.current
  )
  teammate.save!
  WorkspaceMembership.find_or_create_by!(workspace: workspace, user: teammate) { |m| m.role = :member }
  puts "Seeded ana@pipelinehq.test / AnaTeam!2026PipelineHQ"

  Current.workspace = workspace

  # -------- CRM: stages --------
  stages_spec = [
    { name: "Prospecção",   position: 1, color: "#94a3b8" },
    { name: "Qualificação", position: 2, color: "#eab308" },
    { name: "Proposta",     position: 3, color: "#3b82f6" },
    { name: "Negociação",   position: 4, color: "#8b5cf6" },
    { name: "Fechamento",   position: 5, color: "#10b981" }
  ]
  stages = stages_spec.map do |attrs|
    workspace.stages.find_or_create_by!(name: attrs[:name]) do |s|
      s.position = attrs[:position]
      s.color    = attrs[:color]
    end
  end
  by_stage = stages.index_by(&:name)

  # -------- CRM: accounts --------
  accounts_spec = [
    { name: "Acme Tecnologia",  industry: "SaaS",             website: "acme.com.br",     notes: "Cliente estratégico. Expansão prevista Q3." },
    { name: "Nova Ventures",    industry: "Fintech",          website: "nova.finance",    notes: "Levantou Série A recente. Time de TI em crescimento." },
    { name: "Boreal Logística", industry: "Logística",        website: "boreal.log.br",   notes: "Frota de 240 veículos. Foco em telemetria." },
    { name: "Vertigo Studios",  industry: "Agência criativa", website: "vertigo.studio",  notes: "Rebrand grande em andamento com 4 marcas." },
    { name: "Delta Manufatura", industry: "Indústria",        website: "deltamanuf.com",  notes: "Grupo com 3 plantas industriais no interior de SP." }
  ]
  accounts = accounts_spec.map do |attrs|
    workspace.accounts.find_or_create_by!(name: attrs[:name]) do |a|
      a.industry = attrs[:industry]
      a.website  = attrs[:website]
      a.notes    = attrs[:notes]
    end
  end
  by_account = accounts.index_by(&:name)

  # -------- CRM: contacts (primeiro é o "contato principal") --------
  contacts_spec = [
    { account: "Acme Tecnologia",  name: "Rafael Souza",     email: "rafael.souza@acme.com.br",     phone: "+55 11 98123-4501", role: "VP de Vendas" },
    { account: "Acme Tecnologia",  name: "Fernanda Alves",   email: "fernanda.alves@acme.com.br",   phone: "+55 11 98123-4502", role: "Diretora de Produto" },
    { account: "Nova Ventures",    name: "Marina Costa",     email: "marina.costa@nova.finance",    phone: "+55 21 99422-8810", role: "CFO" },
    { account: "Nova Ventures",    name: "Bruno Lima",       email: "bruno.lima@nova.finance",      phone: "+55 21 99422-8811", role: "Gerente de TI" },
    { account: "Boreal Logística", name: "Carla Menezes",    email: "carla.menezes@boreal.log.br",  phone: "+55 41 99188-3320", role: "COO" },
    { account: "Vertigo Studios",  name: "João Prado",       email: "joao.prado@vertigo.studio",    phone: "+55 11 97501-2288", role: "Sócio-fundador" },
    { account: "Delta Manufatura", name: "Camila Rocha",     email: "camila.rocha@deltamanuf.com",  phone: "+55 19 98700-1140", role: "Compras" }
  ]
  contacts = contacts_spec.map do |attrs|
    account = by_account.fetch(attrs[:account])
    workspace.contacts.find_or_create_by!(email: attrs[:email]) do |c|
      c.account = account
      c.name    = attrs[:name]
      c.phone   = attrs[:phone]
      c.role    = attrs[:role]
    end
  end
  primary_contact = contacts.first # Rafael Souza — contato principal exibido nos hero shots
  by_contact = contacts.index_by(&:email)

  # -------- CRM: deals (primeiro é o "deal hero" ancorado no contato principal) --------
  deals_spec = [
    { title: "Acme Q3 Expansion",    account: "Acme Tecnologia",  contact: "rafael.souza@acme.com.br",    stage: "Proposta",     amount_cents: 180_000_00, expected_close_on: Date.current + 21.days, status: "open" },
    { title: "Acme Onboarding",      account: "Acme Tecnologia",  contact: "fernanda.alves@acme.com.br",  stage: "Negociação",   amount_cents:  62_000_00, expected_close_on: Date.current + 10.days, status: "open" },
    { title: "Nova Fintech Rollout", account: "Nova Ventures",    contact: "marina.costa@nova.finance",   stage: "Qualificação", amount_cents: 245_000_00, expected_close_on: Date.current + 45.days, status: "open" },
    { title: "Nova TI Renovation",   account: "Nova Ventures",    contact: "bruno.lima@nova.finance",     stage: "Prospecção",   amount_cents:  48_000_00, expected_close_on: Date.current + 60.days, status: "open" },
    { title: "Boreal Frota",         account: "Boreal Logística", contact: "carla.menezes@boreal.log.br", stage: "Fechamento",   amount_cents: 320_000_00, expected_close_on: Date.current -  3.days, status: "won" },
    { title: "Vertigo Rebrand",      account: "Vertigo Studios",  contact: "joao.prado@vertigo.studio",   stage: "Proposta",     amount_cents:  78_500_00, expected_close_on: Date.current + 18.days, status: "open" },
    { title: "Delta ERP Piloto",     account: "Delta Manufatura", contact: "camila.rocha@deltamanuf.com", stage: "Qualificação", amount_cents: 155_000_00, expected_close_on: Date.current + 35.days, status: "open" },
    { title: "Delta Compras Q4",     account: "Delta Manufatura", contact: "camila.rocha@deltamanuf.com", stage: "Prospecção",   amount_cents:  92_000_00, expected_close_on: Date.current - 12.days, status: "lost" }
  ]
  deals = deals_spec.map do |attrs|
    workspace.deals.find_or_create_by!(title: attrs[:title]) do |d|
      d.account           = by_account.fetch(attrs[:account])
      d.contact           = by_contact.fetch(attrs[:contact])
      d.stage             = by_stage.fetch(attrs[:stage])
      d.amount_cents      = attrs[:amount_cents]
      d.currency          = "BRL"
      d.expected_close_on = attrs[:expected_close_on]
      d.status            = attrs[:status]
    end
  end
  hero_deal = deals.first
  by_deal = deals.index_by(&:title)

  # -------- CRM: activities (hero deal recebe 4, outros 1-2 cada) --------
  activities_spec = [
    { deal: "Acme Q3 Expansion",    kind: "call",    subject: "Discovery call com Rafael",         body: "Rafael confirmou budget de R$ 180k e prazo de fechamento em 3 semanas.",   occurred_at: 3.days.ago },
    { deal: "Acme Q3 Expansion",    kind: "email",   subject: "Material comercial enviado",         body: "Enviado deck + one-pager de ROI. Rafael pediu benchmark com 2 clientes.", occurred_at: 2.days.ago },
    { deal: "Acme Q3 Expansion",    kind: "meeting", subject: "Demo técnica com time da Acme",      body: "Demo com Rafael + CTO + 2 engenheiros. Perguntas sobre SSO e SLA.",       occurred_at: 1.day.ago },
    { deal: "Acme Q3 Expansion",    kind: "note",    subject: "Ajuste de proposta pedido",          body: "Rafael pediu desconto por volume (>500 seats). Revisar até sexta.",       occurred_at: Time.current - 4.hours },

    { deal: "Acme Onboarding",      kind: "meeting", subject: "Kickoff de implementação",           body: "Cronograma de 4 semanas alinhado com Fernanda.",                         occurred_at: 6.hours.ago },
    { deal: "Nova Fintech Rollout", kind: "call",    subject: "Reunião de alinhamento com CFO",     body: "Marina pediu proposta em 2 tiers (essencial e enterprise).",             occurred_at: 5.days.ago },
    { deal: "Nova Fintech Rollout", kind: "email",   subject: "Proposta enviada",                   body: "Proposta detalhada por tier + custo de implementação.",                  occurred_at: 2.days.ago },
    { deal: "Nova TI Renovation",   kind: "call",    subject: "Primeiro contato com Bruno",         body: "Bruno demonstrou interesse. Follow-up marcado pra próxima semana.",        occurred_at: 8.days.ago },
    { deal: "Boreal Frota",         kind: "meeting", subject: "Assinatura de contrato",             body: "Contrato assinado. Kickoff de onboarding próxima terça.",                occurred_at: 3.days.ago },
    { deal: "Vertigo Rebrand",      kind: "meeting", subject: "Apresentação de casos de referência", body: "João gostou dos cases mostrados. Vai levar internamente pros sócios.",   occurred_at: 4.days.ago },
    { deal: "Vertigo Rebrand",      kind: "note",    subject: "João mencionou concorrência",        body: "Está avaliando também a Concorrente X. Precisamos reforçar diferencial.", occurred_at: 1.day.ago },
    { deal: "Delta ERP Piloto",     kind: "call",    subject: "Discovery com Camila",                body: "Time de compras. Precisam integração com SAP existente.",                occurred_at: 6.days.ago },
    { deal: "Delta ERP Piloto",     kind: "email",   subject: "RFP recebido",                        body: "Delta enviou RFP formal com 22 requisitos. Prazo de resposta: 10 dias.",  occurred_at: 2.days.ago }
  ]
  activities_spec.each do |attrs|
    deal = by_deal.fetch(attrs[:deal])
    workspace.activities.find_or_create_by!(deal: deal, subject: attrs[:subject]) do |a|
      a.kind        = attrs[:kind]
      a.body        = attrs[:body]
      a.occurred_at = attrs[:occurred_at]
    end
  end

  # -------- Domain events (alimentam o feed do dashboard) --------
  #
  # Como o DomainEventJob depende do Solid Queue rodando, insere direto na tabela.
  events_spec = [
    { kind: "account.created",        subject: by_account.fetch("Acme Tecnologia"), actor: user,     metadata: { name: "Acme Tecnologia" }, created_at: 10.days.ago },
    { kind: "contact.created",        subject: primary_contact,                     actor: user,     metadata: { name: primary_contact.name, account: "Acme Tecnologia" }, created_at: 9.days.ago },
    { kind: "deal.created",           subject: hero_deal,                           actor: user,     metadata: { title: hero_deal.title, amount_cents: hero_deal.amount_cents }, created_at: 8.days.ago },
    { kind: "activity.created",       subject: hero_deal.activities.order(:occurred_at).last, actor: user, metadata: { kind: "note" }, created_at: 4.hours.ago },
    { kind: "deal.updated",           subject: by_deal.fetch("Boreal Frota"),       actor: user,     metadata: { status: "won" }, created_at: 3.days.ago },
    { kind: "membership.added",       subject: teammate,                            actor: user,     metadata: { role: "member", email: teammate.email_address }, created_at: 7.days.ago }
  ]
  events_spec.each do |attrs|
    workspace.domain_events.find_or_create_by!(kind: attrs[:kind], subject_type: attrs[:subject].class.name, subject_id: attrs[:subject].id) do |e|
      e.actor      = attrs[:actor]
      e.metadata   = attrs[:metadata]
      e.created_at = attrs[:created_at]
    end
  end

  puts "Seeded CRM: #{workspace.stages.count} stages, #{workspace.accounts.count} accounts, #{workspace.contacts.count} contacts, #{workspace.deals.count} deals, #{workspace.activities.count} activities, #{workspace.domain_events.count} domain events"
  puts "Contato principal: #{primary_contact.name} (#{primary_contact.email}) — Acme Tecnologia"

  # -------- DM entre Demo e Ana --------
  result = Conversations::FindOrCreateDirect.call(workspace: workspace, initiator: teammate, recipient: user)
  conversation = result.payload
  if conversation.messages.empty?
    Messages::Send.call(conversation: conversation, sender: teammate, body: "Oi! Bem-vindo ao PipelineHQ — qualquer dúvida me chama por aqui.")
    Messages::Send.call(conversation: conversation, sender: teammate, body: "Acabei de subir um lead novo na sua fila, dá uma olhada quando puder.")
    Messages::Send.call(conversation: conversation, sender: user,     body: "Perfeito, obrigado! Acabei de olhar o pipeline. Rafael da Acme mandou pedido de ajuste na proposta — vou revisar hoje.")
    Messages::Send.call(conversation: conversation, sender: teammate, body: "Show! Se precisar de ajuda no cálculo de desconto, tô aqui.")
  end
  puts "Seeded 1 conversa entre Demo User e Ana Ribeiro (#{conversation.messages.count} mensagens)"
end
