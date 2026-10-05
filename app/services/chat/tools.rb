# frozen_string_literal: true

module Chat
  class Tools
    ROW_LIMIT = 10
    ACTIVITY_LIMIT_MAX = 20
    QUERY_MAX = 100
    TEXT_EXCERPT = 300
    DEAL_STATUSES = %w[open won lost].freeze
    NOT_FOUND = { error: "not found" }.freeze

    DEFINITIONS = [
      {
        name: "search_contacts",
        description: "Busca contatos do workspace por nome, email ou cargo. Retorna no máximo #{ROW_LIMIT} linhas.",
        input_schema: {
          type: "object",
          properties: { query: { type: "string", description: "Trecho do nome, email ou cargo" } },
          required: %w[query],
          additionalProperties: false
        }
      },
      {
        name: "search_accounts",
        description: "Busca contas (empresas) do workspace por nome ou setor. Retorna no máximo #{ROW_LIMIT} linhas.",
        input_schema: {
          type: "object",
          properties: { query: { type: "string", description: "Trecho do nome ou setor" } },
          required: %w[query],
          additionalProperties: false
        }
      },
      {
        name: "list_deals",
        description: "Lista negócios do workspace, com filtros opcionais. Retorna no máximo #{ROW_LIMIT} linhas, ordenados pela data prevista de fechamento.",
        input_schema: {
          type: "object",
          properties: {
            stage: { type: "string", description: "Nome exato da etapa do funil (sem diferenciar maiúsculas)" },
            status: { type: "string", enum: DEAL_STATUSES },
            closing_before: { type: "string", description: "Data ISO 8601 (AAAA-MM-DD); só negócios com fechamento previsto até essa data" }
          },
          additionalProperties: false
        }
      },
      {
        name: "deal_summary",
        description: "Resumo de um negócio pelo id: valores, etapa, conta, contato e últimas atividades.",
        input_schema: {
          type: "object",
          properties: { deal_id: { type: "integer" } },
          required: %w[deal_id],
          additionalProperties: false
        }
      },
      {
        name: "recent_activities",
        description: "Atividades mais recentes do workspace (ligações, emails, reuniões, notas, tarefas).",
        input_schema: {
          type: "object",
          properties: { limit: { type: "integer", minimum: 1, maximum: ACTIVITY_LIMIT_MAX } },
          additionalProperties: false
        }
      }
    ].freeze

    HANDLERS = {
      "search_contacts" => :search_contacts,
      "search_accounts" => :search_accounts,
      "list_deals" => :list_deals,
      "deal_summary" => :deal_summary,
      "recent_activities" => :recent_activities
    }.freeze

    class InvalidInput < StandardError; end

    def initialize(workspace:)
      @workspace = workspace
    end

    def call(name, input)
      handler = HANDLERS[name.to_s]
      return error("unknown tool") unless handler

      payload = send(handler, (input || {}).to_h.stringify_keys)
      [ payload.to_json, false ]
    rescue InvalidInput => e
      error(e.message)
    end

    private

    attr_reader :workspace

    def search_contacts(input)
      pattern = like_pattern(input["query"])
      contacts = workspace.contacts.includes(:account)
        .where("contacts.name ILIKE :q OR contacts.email ILIKE :q OR contacts.role ILIKE :q", q: pattern)
        .order(:name, :id).limit(ROW_LIMIT)
      { contacts: contacts.map { |c| contact_json(c).merge(account: own(c.account)&.name) } }
    end

    def search_accounts(input)
      pattern = like_pattern(input["query"])
      accounts = workspace.accounts
        .where("accounts.name ILIKE :q OR accounts.industry ILIKE :q", q: pattern)
        .order(:name, :id).limit(ROW_LIMIT)
      { accounts: accounts.map { |a| account_json(a) } }
    end

    def list_deals(input)
      deals = workspace.deals.includes(:stage, :account)
      deals = filter_by_stage(deals, input["stage"])
      deals = filter_by_status(deals, input["status"])
      deals = deals.where(expected_close_on: ..parse_date(input["closing_before"])) if input["closing_before"].present?
      deals = deals.order(Arel.sql("expected_close_on ASC NULLS LAST"), :id).limit(ROW_LIMIT)
      { deals: deals.map { |d| deal_json(d) } }
    end

    def deal_summary(input)
      deal = workspace.deals.includes(:stage, :account, :contact).find_by(id: integer(input["deal_id"]))
      return NOT_FOUND unless deal

      activities = workspace.activities.where(deal_id: deal.id)
        .order(Arel.sql("occurred_at DESC NULLS LAST"), id: :desc).limit(5)
      deal_json(deal).merge(
        contact: own(deal.contact)&.then { |c| contact_json(c) },
        recent_activities: activities.map { |a| activity_json(a) }
      )
    end

    def recent_activities(input)
      limit = input["limit"].nil? ? ROW_LIMIT : integer(input["limit"]).clamp(1, ACTIVITY_LIMIT_MAX)
      activities = workspace.activities.includes(:deal)
        .order(Arel.sql("occurred_at DESC NULLS LAST"), id: :desc).limit(limit)
      { activities: activities.map { |a| activity_json(a).merge(deal: own(a.deal)&.then { |d| { id: d.id, title: d.title } }) } }
    end

    def filter_by_stage(deals, stage)
      return deals if stage.blank?

      deals.joins(:stage).where(stages: { workspace_id: workspace.id })
        .where("LOWER(stages.name) = ?", stage.to_s.strip.downcase.first(QUERY_MAX))
    end

    def filter_by_status(deals, status)
      return deals if status.blank?
      raise InvalidInput, "invalid status: use #{DEAL_STATUSES.join(', ')}" unless DEAL_STATUSES.include?(status)

      deals.where(status: status)
    end

    def contact_json(contact)
      { id: contact.id, name: contact.name, email: contact.email, phone: contact.phone, role: contact.role }
    end

    def account_json(account)
      { id: account.id, name: account.name, industry: account.industry, website: account.website, notes: excerpt(account.notes) }
    end

    def deal_json(deal)
      {
        id: deal.id, title: deal.title, status: deal.status, stage: own(deal.stage)&.name,
        amount: deal.amount_cents && format("%.2f", deal.amount_cents / 100.0), currency: deal.currency,
        expected_close_on: deal.expected_close_on&.iso8601, account: own(deal.account)&.name
      }
    end

    def activity_json(activity)
      {
        id: activity.id, kind: activity.kind, subject: activity.subject,
        body: excerpt(activity.body), occurred_at: activity.occurred_at&.iso8601
      }
    end

    def own(record)
      record if record&.workspace_id == workspace.id
    end

    def like_pattern(query)
      query = query.to_s.strip
      raise InvalidInput, "query is required" if query.empty?
      raise InvalidInput, "query too long (max #{QUERY_MAX})" if query.length > QUERY_MAX

      "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      raise InvalidInput, "closing_before must be an ISO 8601 date (YYYY-MM-DD)"
    end

    def integer(value)
      Integer(value, exception: false) || raise(InvalidInput, "expected an integer")
    end

    def excerpt(text)
      text.to_s.truncate(TEXT_EXCERPT).presence
    end

    def error(message)
      [ { error: message }.to_json, true ]
    end
  end
end
