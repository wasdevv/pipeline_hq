# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:workspace) { create(:workspace, owner: create(:user)) }
  let(:user)      { create(:user) }
  let(:other_ws)  { create(:workspace, owner: create(:user)) }

  before do
    allow(Current).to receive(:workspace).and_return(workspace)
  end

  context "when record belongs to current workspace" do
    let(:record) { double("Record", workspace_id: workspace.id) }

    context "with owner role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

      it { is_expected.to permit_actions(:index, :show, :create, :update, :destroy) }
      it { is_expected.to permit_actions(:new, :edit) }
    end

    context "with admin role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :admin) }

      it { is_expected.to permit_actions(:index, :show, :create, :update, :destroy) }
    end

    context "with member role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

      it { is_expected.to permit_actions(:index, :show, :create, :update) }
      it { is_expected.to forbid_only_actions(:destroy) }
    end

    context "with viewer role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :viewer) }

      it { is_expected.to permit_only_actions(:index, :show) }
      it { is_expected.to forbid_actions(:new, :edit, :create, :update, :destroy) }
    end

    context "with no membership" do
      it { is_expected.to forbid_all_actions }
    end
  end

  context "scoped_to_workspace? guard" do
    let(:record) { double("Record", workspace_id: other_ws.id) }

    context "with owner role in current workspace" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

      it "forbids show (record is in another workspace)" do
        expect(policy.show?).to be(false)
      end

      it "forbids update (cross-workspace)" do
        expect(policy.update?).to be(false)
      end

      it "forbids destroy (cross-workspace)" do
        expect(policy.destroy?).to be(false)
      end
    end
  end

  describe "Scope#resolve" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

    let(:record) { double("Record", workspace_id: workspace.id) }

    it "delegates to workspace_id filter via Current.workspace" do
      scope = described_class::Scope.new(user, Account)
      allow(Current).to receive(:workspace).and_return(workspace)
      resolved = scope.resolve
      expect(resolved.where_values_hash["workspace_id"]).to eq(workspace.id)
    end
  end
end
