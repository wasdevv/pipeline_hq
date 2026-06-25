# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspaces::Create do
  describe ".call" do
    subject(:result) { described_class.call(user: user, name: name) }

    let!(:user) { create(:user) }
    let(:name)  { "Acme Corp" }

    context "with valid params" do
      it_behaves_like "a successful Result", code: :created

      it "creates a workspace" do
        expect { result }.to change(Workspace, :count).by(1)
      end

      it "returns the workspace as payload" do
        expect(result.payload).to be_a(Workspace).and be_persisted
        expect(result.payload.name).to eq("Acme Corp")
      end

      it "creates an owner membership" do
        expect { result }.to change(WorkspaceMembership, :count).by(1)
        expect(result.payload.workspace_memberships.owner.exists?(user_id: user.id)).to be(true)
      end

      it "sets user.current_workspace_id to the new workspace" do
        result
        expect(user.reload.current_workspace_id).to eq(result.payload.id)
      end

      it "generates a slug from the name" do
        expect(result.payload.slug).to eq("acme-corp")
      end
    end

    context "with a blank name" do
      let(:name) { "" }

      it_behaves_like "a failed Result", code: :invalid

      it "does not create an additional workspace" do
        baseline = Workspace.count
        result
        expect(Workspace.count).to eq(baseline)
      end

      it "exposes validation errors" do
        expect(result.errors[:name]).to be_present
      end
    end

    context "when user is blank" do
      let!(:user) { nil }

      it_behaves_like "a failed Result", code: :user_blank

      it "does not create a workspace" do
        expect { result }.not_to change(Workspace, :count)
      end
    end

    context "slug collision" do
      before do
        5.times { |n| create(:workspace, slug: n.zero? ? "acme-corp" : "acme-corp-#{n + 1}") }
      end

      it "returns :slug_taken when all slug candidates are exhausted" do
        expect(result.code).to be_in(%i[created slug_taken])
      end

      it "succeeds with a hex fallback when only base slug is taken" do
        Workspace.where(slug: "acme-corp-2").delete_all
        expect(described_class.call(user: user, name: name)).to be_success
      end
    end

    context "atomicity" do
      it "rolls back workspace creation if membership fails" do
        allow(WorkspaceMembership).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        baseline = Workspace.count
        expect { result rescue nil }.not_to change { Workspace.count }
        expect(Workspace.count).to eq(baseline)
      end

      it "returns :slug_taken when a concurrent insert raises RecordNotUnique" do
        allow_any_instance_of(Workspace).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

        expect(result).to be_failure
        expect(result.code).to eq(:slug_taken)
      end
    end
  end
end
