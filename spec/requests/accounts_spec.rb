# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounts", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:create_params) { { name: "New Account", industry: "SaaS", website: "https://x.com", notes: "" } }
  let(:update_params) { { name: "Updated Account", industry: "Fintech", website: "https://y.com", notes: "edit" } }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold", model: Account, factory: :account, attribute_path: "accounts", skip_create: true

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
    let!(:existing) { create(:account) }

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
end
