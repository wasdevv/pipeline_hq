# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contacts", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:account)   { create(:account, workspace: workspace) }
  let(:create_params) { { account_id: account.id, name: "New Contact", email: "new@x.test", phone: "+55 11", role: "Buyer" } }
  let(:update_params) { { account_id: account.id, name: "Updated Contact", email: "upd@x.test", phone: "+55 21", role: "Owner" } }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold",
    model: Contact,
    factory: :contact,
    attribute_path: "contacts",
    invalid_attribute: :account_id,
    skip_create: false do
    let(:record) { create(:contact, workspace: workspace, account: account) }
  end
end
