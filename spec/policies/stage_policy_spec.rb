# frozen_string_literal: true

require "rails_helper"
require_relative "shared_examples/crm_policy"

RSpec.describe StagePolicy do
  it_behaves_like "a CRM policy", factory: :stage

  describe "destroy? override" do
    subject(:policy) { described_class.new(user, record) }

    let(:workspace) { create(:workspace, owner: create(:user)) }
    let(:user)      { create(:user) }
    let(:record)    { create(:stage, workspace: workspace) }

    before { allow(Current).to receive(:workspace).and_return(workspace) }

    context "with member role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :member) }

      it "forbids destroy (member cannot destroy stages)" do
        expect(policy.destroy?).to be(false)
      end
    end

    context "with admin role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: :admin) }

      it "permits destroy" do
        expect(policy.destroy?).to be(true)
      end
    end
  end
end
