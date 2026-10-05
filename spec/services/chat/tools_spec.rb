# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::Tools do
  subject(:tools) { described_class.new(workspace: workspace) }

  let(:workspace)       { create(:workspace) }
  let(:other_workspace) { create(:workspace) }
  let(:account)         { create(:account, workspace: workspace, name: "Acme Tecnologia", industry: "SaaS") }
  let(:contact)         { create(:contact, workspace: workspace, account: account, name: "Rafael Souza") }
  let(:stage)           { create(:stage, workspace: workspace, name: "Proposta") }
  let(:deal)            { create(:deal, workspace: workspace, account: account, contact: contact, stage: stage, title: "Acme Q3") }

  let(:foreign_account) { create(:account, workspace: other_workspace, name: "Acme Concorrente") }
  let(:foreign_contact) { create(:contact, workspace: other_workspace, account: foreign_account, name: "Rafael Outro") }
  let(:foreign_stage)   { create(:stage, workspace: other_workspace, name: "Proposta") }
  let(:foreign_deal) do
    create(:deal, workspace: other_workspace, account: foreign_account, contact: foreign_contact, stage: foreign_stage, title: "Segredo")
  end

  def run(name, input = {})
    output, is_error = tools.call(name, input)
    [ JSON.parse(output), is_error ]
  end

  it "declares exactly the five read-only tools, none of them taking a workspace" do
    expect(described_class::DEFINITIONS.pluck(:name))
      .to eq(%w[search_contacts search_accounts list_deals deal_summary recent_activities])
    expect(described_class::DEFINITIONS.flat_map { |d| d[:input_schema][:properties].keys }).not_to include(a_string_matching(/workspace/))
  end

  describe "deal_summary" do
    it "returns the deal with stage, account, contact and recent activities" do
      create(:activity, workspace: workspace, deal: deal, subject: "Ligação de follow-up")

      payload, is_error = run("deal_summary", "deal_id" => deal.id)

      expect(is_error).to be(false)
      expect(payload).to include("id" => deal.id, "title" => "Acme Q3", "stage" => "Proposta", "account" => "Acme Tecnologia", "amount" => "1000.00")
      expect(payload["contact"]).to include("name" => "Rafael Souza")
      expect(payload["recent_activities"].pluck("subject")).to eq([ "Ligação de follow-up" ])
    end

    it "answers a deal id from another workspace exactly like a nonexistent id" do
      foreign = run("deal_summary", "deal_id" => foreign_deal.id)
      missing = run("deal_summary", "deal_id" => Deal.maximum(:id).to_i + 1_000)

      expect(foreign).to eq([ { "error" => "not found" }, false ])
      expect(foreign).to eq(missing)
    end

    it "rejects a non-integer id without querying arbitrary input" do
      payload, is_error = run("deal_summary", "deal_id" => "1 OR 1=1")

      expect(is_error).to be(true)
      expect(payload["error"]).to match(/integer/)
    end
  end

  describe "search_contacts" do
    it "matches by name inside the workspace only" do
      contact
      foreign_contact

      payload, = run("search_contacts", "query" => "rafael")

      expect(payload["contacts"].pluck("name")).to eq([ "Rafael Souza" ])
      expect(payload["contacts"].first["account"]).to eq("Acme Tecnologia")
    end

    it "treats % and _ as literals" do
      contact

      payload, = run("search_contacts", "query" => "%")

      expect(payload["contacts"]).to be_empty
    end

    it "caps the rows returned" do
      create_list(:contact, described_class::ROW_LIMIT + 3, workspace: workspace, account: account)

      payload, = run("search_contacts", "query" => "Contact")

      expect(payload["contacts"].size).to eq(described_class::ROW_LIMIT)
    end

    it "rejects empty and oversized queries" do
      expect(run("search_contacts", "query" => " ").last).to be(true)
      expect(run("search_contacts", "query" => "a" * 101).last).to be(true)
    end
  end

  describe "search_accounts" do
    it "matches by name or industry inside the workspace, truncating notes" do
      account.update!(notes: "x" * 1_000)
      foreign_account

      payload, = run("search_accounts", "query" => "acme")

      expect(payload["accounts"].pluck("name")).to eq([ "Acme Tecnologia" ])
      expect(payload["accounts"].first["notes"].length).to eq(described_class::TEXT_EXCERPT)
    end
  end

  describe "list_deals" do
    before do
      deal
      foreign_deal
    end

    it "lists only the workspace deals" do
      payload, = run("list_deals")

      expect(payload["deals"].pluck("title")).to eq([ "Acme Q3" ])
    end

    it "filters by stage name, status and closing date" do
      won = create(:deal, workspace: workspace, account: account, contact: contact, stage: stage,
                          status: "won", expected_close_on: Date.new(2026, 1, 10))

      expect(run("list_deals", "stage" => "proposta").first["deals"].size).to eq(2)
      expect(run("list_deals", "status" => "won").first["deals"].pluck("id")).to eq([ won.id ])
      expect(run("list_deals", "closing_before" => "2026-02-01").first["deals"].pluck("id")).to eq([ won.id ])
    end

    it "rejects an unknown status and a malformed date" do
      expect(run("list_deals", "status" => "deleted")).to match([ { "error" => /invalid status/ }, true ])
      expect(run("list_deals", "closing_before" => "amanhã")).to match([ { "error" => /ISO 8601/ }, true ])
    end

    it "hides an account name that belongs to another workspace" do
      deal.update_columns(account_id: foreign_account.id)

      payload, = run("list_deals")

      expect(payload["deals"].first["account"]).to be_nil
    end
  end

  describe "recent_activities" do
    it "returns the workspace activities newest first, clamped to the max limit" do
      old = create(:activity, workspace: workspace, deal: deal, occurred_at: 2.days.ago)
      new = create(:activity, workspace: workspace, deal: deal, occurred_at: 1.hour.ago)
      create(:activity, workspace: other_workspace, deal: foreign_deal)

      payload, = run("recent_activities", "limit" => 500)

      expect(payload["activities"].pluck("id")).to eq([ new.id, old.id ])
      expect(payload["activities"].first["deal"]).to eq("id" => deal.id, "title" => "Acme Q3")
    end
  end

  it "returns an error result for an unknown tool name" do
    expect(run("destroy_all_deals", {})).to eq([ { "error" => "unknown tool" }, true ])
  end
end
