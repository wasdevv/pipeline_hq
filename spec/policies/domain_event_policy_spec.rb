# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainEventPolicy do
  subject(:policy) { described_class.new(user, DomainEvent) }

  let(:owner)     { create(:user) }
  let(:workspace) { create(:workspace, owner: owner) }
  let(:user)      { create(:user) }

  before { allow(Current).to receive(:workspace).and_return(workspace) }

  context "with owner role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :owner) }

    it { is_expected.to permit_action(:index) }
  end

  context "with admin role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :admin) }

    it { is_expected.to permit_action(:index) }
  end

  context "with member role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

    it { is_expected.to permit_action(:index) }
  end

  context "with viewer role" do
    before { create(:workspace_membership, user: user, workspace: workspace, role: :viewer) }

    it { is_expected.to permit_action(:index) }
  end

  context "with no membership" do
    it { is_expected.to forbid_action(:index) }
  end

  describe "#show?" do
    it "is always false" do
      create(:workspace_membership, user: user, workspace: workspace, role: :owner)
      expect(policy.show?).to be(false)
    end
  end

  describe "Scope" do
    let!(:own_event)   { create(:domain_event, workspace: workspace) }
    let!(:other_ws)    { create(:workspace, owner: create(:user)) }
    let!(:other_event) { create(:domain_event, workspace: other_ws) }

    before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

    it "returns only events belonging to current workspace" do
      scope = described_class::Scope.new(user, DomainEvent).resolve
      expect(scope).to include(own_event)
      expect(scope).not_to include(other_event)
    end
  end
end
