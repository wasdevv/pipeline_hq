# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stages", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:create_params) { { name: "New Stage", position: 100, color: "#000000" } }
  let(:update_params) { { name: "Updated Stage", position: 200, color: "#ffffff" } }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold", model: Stage, factory: :stage, attribute_path: "stages"
end
