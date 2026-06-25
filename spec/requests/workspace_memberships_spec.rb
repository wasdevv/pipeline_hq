# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WorkspaceMemberships", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  describe "GET /workspaces/:workspace_id/memberships" do
    it "lists members of the current workspace" do
      get workspace_memberships_path(workspace_id: user.current_workspace.id)
      expect(response).to have_http_status(:ok)
    end
  end
end
