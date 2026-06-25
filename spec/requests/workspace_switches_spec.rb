# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WorkspaceSwitches", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  describe "POST /workspaces/:id/switch" do
    context "when the user is a member of the target workspace" do
      let(:second_workspace) do
        Workspaces::Create.call(user: user, name: "Second").payload
      end

      it "switches and redirects to root" do
        post switch_workspace_path(second_workspace)

        expect(response).to redirect_to(root_path)
        expect(user.reload.current_workspace_id).to eq(second_workspace.id)
        expect(flash[:notice]).to eq(I18n.t("workspaces.switched"))
      end
    end

    context "when the user is not a member" do
      let(:foreign_workspace) { create(:user).current_workspace }

      it "does not switch and redirects to root with an alert" do
        original_id = user.current_workspace_id
        post switch_workspace_path(foreign_workspace)

        expect(response).to redirect_to(root_path)
        expect(user.reload.current_workspace_id).to eq(original_id)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end
end
