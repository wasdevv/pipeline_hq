# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activities", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:account)   { create(:account, workspace: workspace) }
  let(:contact)   { create(:contact, workspace: workspace, account: account) }
  let(:stage)     { create(:stage, workspace: workspace) }
  let(:deal)      { create(:deal, workspace: workspace, account: account, contact: contact, stage: stage) }
  let(:create_params) do
    {
      deal_id:     deal.id,
      kind:        "call",
      subject:     "Discovery call",
      body:        "Initial scoping",
      occurred_at: Time.current
    }
  end
  let(:update_params) { create_params.merge(subject: "Updated subject", kind: "email") }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold",
    model: Activity,
    factory: :activity,
    attribute_path: "activities",
    invalid_attribute: :deal_id,
    skip_create: false do
    let(:record) { create(:activity, workspace: workspace, deal: deal) }
  end
end
