# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Deals", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:account)   { create(:account, workspace: workspace) }
  let(:contact)   { create(:contact, workspace: workspace, account: account) }
  let(:stage)     { create(:stage, workspace: workspace) }
  let(:create_params) do
    {
      title:             "New Deal",
      account_id:        account.id,
      contact_id:        contact.id,
      stage_id:          stage.id,
      amount_cents:      500_000,
      currency:          "BRL",
      expected_close_on: 45.days.from_now.to_date,
      status:            "open"
    }
  end
  let(:update_params) { create_params.merge(title: "Updated Deal", amount_cents: 750_000) }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold",
    model: Deal,
    factory: :deal,
    attribute_path: "deals",
    invalid_attribute: :account_id,
    skip_create: false do
    let(:record) { create(:deal, workspace: workspace, account: account, contact: contact, stage: stage) }
  end

  describe "RecordsDomainEvents concern" do
    it "enqueues deal.created event on successful POST create" do
      expect {
        post deals_path, params: { deal: create_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "deal.created")
      )
    end

    it "enqueues deal.updated event on successful PATCH update" do
      existing = create(:deal, workspace: workspace, account: account, contact: contact, stage: stage)
      expect {
        patch deal_path(existing), params: { deal: update_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "deal.updated")
      )
    end

    it "enqueues deal.destroyed event on successful DELETE destroy" do
      existing = create(:deal, workspace: workspace, account: account, contact: contact, stage: stage)
      expect {
        delete deal_path(existing)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "deal.destroyed")
      )
    end

    it "does NOT enqueue an event when create fails (save returns false)" do
      allow_any_instance_of(Deal).to receive(:save).and_return(false)
      expect {
        post deals_path, params: { deal: create_params }
      }.not_to have_enqueued_job(DomainEventJob)
    end
  end
end
