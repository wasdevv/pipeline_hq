# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspacePolicy do
  subject(:policy) { described_class.new(user, workspace) }

  let(:owner)     { create(:user) }
  let(:workspace) { create(:workspace, owner: owner) }
  let(:user)      { create(:user) }

  before { allow(Current).to receive(:workspace).and_return(workspace) }

  context "with owner role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

    it { is_expected.to permit_actions(:index, :show, :create, :update) }
    it { is_expected.to forbid_only_actions(:destroy) }
  end

  context "with admin role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :admin) }

    it { is_expected.to permit_actions(:index, :show, :create, :update) }
    it { is_expected.to forbid_only_actions(:destroy) }
  end

  context "with member role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

    it { is_expected.to permit_actions(:index, :show, :create) }
    it { is_expected.to forbid_actions(:update, :destroy) }
  end

  context "with viewer role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :viewer) }

    it { is_expected.to permit_actions(:index, :show, :create) }
    it { is_expected.to forbid_actions(:update, :destroy) }
  end

  context "with no membership" do
    it { is_expected.to permit_actions(:index, :create) }
    it { is_expected.to forbid_actions(:show, :update, :destroy) }
  end

  context "destroy? is always false" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

    it { is_expected.to forbid_only_actions(:destroy) }
  end

  describe "Scope" do
    let!(:other_ws) { create(:workspace, owner: create(:user)) }

    before do
      create(:workspace_membership, user: user, workspace: workspace, role: :member)
    end

    it "returns only workspaces the user is a member of" do
      scope = described_class::Scope.new(user, Workspace)
      result = scope.resolve
      expect(result).to include(workspace)
      expect(result).not_to include(other_ws)
    end
  end
end
