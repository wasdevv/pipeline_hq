# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Deals", type: :request do
  include ActiveJob::TestHelper

  let(:user)    { create(:user) }
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:stage)   { create(:stage) }
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

  it_behaves_like "a standard scaffold", model: Deal, factory: :deal, attribute_path: "deals", invalid_attribute: :account_id, skip_create: true
end
