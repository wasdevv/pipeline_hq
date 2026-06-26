# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounts", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:create_params) { { name: "New Account", industry: "SaaS", website: "https://x.com", notes: "" } }
  let(:update_params) { { name: "Updated Account", industry: "Fintech", website: "https://y.com", notes: "edit" } }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold",
    model: Account,
    factory: :account,
    attribute_path: "accounts",
    skip_create: false do
    let(:record) { create(:account, workspace: workspace) }
  end

  context "when persistence fails" do
    before { allow_any_instance_of(Account).to receive(:save).and_return(false) }

    it "POST create re-renders the form with 422 (html)" do
      post accounts_path, params: { account: create_params }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "POST create returns 422 (json)" do
      post accounts_path,
           params:  { account: create_params }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "when update fails" do
    let!(:existing) { create(:account, workspace: workspace) }

    before { allow_any_instance_of(Account).to receive(:update).and_return(false) }

    it "PATCH update re-renders the form with 422 (html)" do
      patch account_path(existing), params: { account: update_params }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "PATCH update returns 422 (json)" do
      patch account_path(existing),
            params:  { account: update_params }.to_json,
            headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "cross-workspace isolation" do
    let(:other_user)      { create(:user) }
    let(:other_workspace) { other_user.current_workspace }

    it "returns 404 when fetching an account from another workspace" do
      foreign_account = create(:account, workspace: other_workspace)
      get account_path(foreign_account)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "RecordsDomainEvents concern" do
    it "enqueues account.created event on successful POST create" do
      expect {
        post accounts_path, params: { account: create_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "account.created")
      )
    end

    it "enqueues account.updated event on successful PATCH update" do
      existing = create(:account, workspace: workspace)
      expect {
        patch account_path(existing), params: { account: update_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "account.updated")
      )
    end

    it "enqueues account.destroyed event on successful DELETE destroy" do
      existing = create(:account, workspace: workspace)
      expect {
        delete account_path(existing)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "account.destroyed")
      )
    end

    it "does NOT enqueue an event when create fails (save returns false)" do
      allow_any_instance_of(Account).to receive(:save).and_return(false)
      expect {
        post accounts_path, params: { account: create_params }
      }.not_to have_enqueued_job(DomainEventJob)
    end
  end
end
