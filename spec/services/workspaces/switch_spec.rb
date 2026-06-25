# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspaces::Switch do
  describe ".call" do
    let!(:user)      { create(:user) }
    let(:other_user) { create(:user) }
    let(:second_ws)  { Workspaces::Create.call(user: user, name: "Second").payload }
    let(:foreign_ws) { other_user.current_workspace }

    subject(:result) { described_class.call(user: user, workspace: target) }

    context "when user is a member of the target workspace" do
      let(:target) { second_ws }

      it_behaves_like "a successful Result", code: :switched

      it "updates user.current_workspace_id" do
        result
        expect(user.reload.current_workspace_id).to eq(second_ws.id)
      end

      it "returns the workspace as payload" do
        expect(result.payload).to eq(second_ws)
      end
    end

    context "when user is not a member of the target workspace" do
      let(:target) { foreign_ws }

      it_behaves_like "a failed Result", code: :not_member

      it "does not change current_workspace_id" do
        original = user.current_workspace_id
        result
        expect(user.reload.current_workspace_id).to eq(original)
      end
    end

    context "when workspace is nil" do
      let(:target) { nil }

      it_behaves_like "a failed Result", code: :not_found
    end
  end
end
