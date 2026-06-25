# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workspaces", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  describe "GET /workspaces/new" do
    it "renders the form" do
      get new_workspace_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /workspaces" do
    it "creates a workspace and switches the current user to it" do
      expect {
        post workspaces_path, params: { workspace: { name: "Acme Corp" } }
      }.to change(Workspace, :count).by(1)

      expect(response).to have_http_status(:found)
      expect(user.reload.current_workspace.name).to eq("Acme Corp")
    end

    it "re-renders with errors on invalid params" do
      post workspaces_path, params: { workspace: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /workspaces/:id" do
    it "renders the workspace owned by current user" do
      get workspace_path(workspace)
      expect(response).to have_http_status(:ok)
    end

    it "redirects with an unauthorized flash when accessing another workspace" do
      foreign = create(:user).current_workspace
      get workspace_path(foreign)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
    end
  end

  describe "GET /workspaces/:id/edit" do
    it "renders the edit form" do
      get edit_workspace_path(workspace)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /workspaces/:id" do
    it "updates the workspace name and redirects to show" do
      patch workspace_path(workspace), params: { workspace: { name: "Renamed" } }

      expect(response).to redirect_to(workspace_path(workspace))
      expect(workspace.reload.name).to eq("Renamed")
    end

    it "re-renders edit with 422 on invalid params" do
      patch workspace_path(workspace), params: { workspace: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(workspace.reload.name).not_to eq("")
    end
  end
end
