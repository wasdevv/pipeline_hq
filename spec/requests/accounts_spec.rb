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

  it_behaves_like "a standard scaffold", model: Account, factory: :account, attribute_path: "accounts"
end
