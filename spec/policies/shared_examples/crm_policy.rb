# frozen_string_literal: true

RSpec.shared_examples "a CRM policy" do |factory:|
  subject(:policy) { described_class.new(user, record) }

  let(:workspace) { create(:workspace, owner: create(:user)) }
  let(:user)      { create(:user) }
  let(:record)    { create(factory, workspace: workspace) }

  before { allow(Current).to receive(:workspace).and_return(workspace) }

  context "with owner role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

    it { is_expected.to permit_actions(:index, :show, :create, :update, :destroy) }
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

    it { is_expected.to forbid_actions(:create, :update, :destroy) }
    it { is_expected.to permit_actions(:index, :show) }
  end

  context "with no membership" do
    it { is_expected.to forbid_all_actions }
  end

  context "cross-workspace" do
    let(:other_ws) { create(:workspace, owner: create(:user)) }
    let(:record)   { create(factory, workspace: other_ws) }

    before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

    it "forbids show (record in another workspace)" do
      expect(policy.show?).to be(false)
    end

    it "forbids update (record in another workspace)" do
      expect(policy.update?).to be(false)
    end

    it "forbids destroy (record in another workspace)" do
      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

    it "scopes to current workspace" do
      scope = described_class::Scope.new(user, record.class)
      allow(Current).to receive(:workspace).and_return(workspace)
      expect(scope.resolve.where_values_hash["workspace_id"]).to eq(workspace.id)
    end
  end
end
