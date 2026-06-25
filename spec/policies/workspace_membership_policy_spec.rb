# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceMembershipPolicy do
  subject(:policy) { described_class.new(user, membership) }

  let(:workspace)  { create(:workspace, owner: create(:user)) }
  let(:user)       { create(:user) }
  let(:membership) { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

  before { allow(Current).to receive(:workspace).and_return(workspace) }

  context "when user is a member of current workspace" do
    it { is_expected.to permit_only_actions(:index) }
    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end

  context "when user is not a member of current workspace" do
    let(:other_ws) { create(:workspace, owner: create(:user)) }

    before { allow(Current).to receive(:workspace).and_return(other_ws) }

    it { is_expected.to forbid_all_actions }
  end

  describe "Scope" do
    it "scopes to memberships of current workspace" do
      _other_member = create(:workspace_membership, workspace: workspace, role: :member)
      scope = described_class::Scope.new(user, WorkspaceMembership)
      allow(Current).to receive(:workspace).and_return(workspace)
      result = scope.resolve
      expect(result.where_values_hash["workspace_id"]).to eq(workspace.id)
    end
  end
end
