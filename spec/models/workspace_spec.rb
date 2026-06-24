# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspace, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User").inverse_of(:owned_workspaces) }
    it { is_expected.to have_many(:workspace_memberships).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:members).through(:workspace_memberships).source(:user) }
    it { is_expected.to have_many(:accounts).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:contacts).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:stages).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:deals).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:activities).dependent(:destroy).inverse_of(:workspace) }
    it { is_expected.to have_many(:domain_events).dependent(:destroy).inverse_of(:workspace) }
  end

  describe "validations" do
    subject { build(:workspace) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(80) }

    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_length_of(:slug).is_at_least(2).is_at_most(80) }

    it "rejects slugs with uppercase letters" do
      workspace = build(:workspace, slug: "MyWorkspace")
      expect(workspace).not_to be_valid
      expect(workspace.errors[:slug]).to be_present
    end

    it "rejects slugs with spaces" do
      workspace = build(:workspace, slug: "my workspace")
      expect(workspace).not_to be_valid
      expect(workspace.errors[:slug]).to be_present
    end

    it "accepts slugs with lowercase letters, digits and hyphens" do
      workspace = build(:workspace, slug: "my-workspace-2026")
      expect(workspace).to be_valid
    end

    it "rejects duplicate slugs" do
      create(:workspace, slug: "taken-slug")
      duplicate = build(:workspace, slug: "taken-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end
  end

  describe "slug uniqueness enforced at the DB level" do
    it "raises on duplicate slug bypassing model validations" do
      existing = create(:workspace, slug: "unique-slug")
      duplicate = build(:workspace, slug: "unique-slug", owner: existing.owner)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "dependent: :destroy cascades" do
    let!(:workspace) { create(:workspace) }
    let!(:account)   { create(:account, workspace: workspace) }

    it "destroys child accounts when workspace is destroyed" do
      expect { workspace.destroy! }.to change(Account, :count).by(-1)
    end
  end

  describe "#members through :workspace_memberships" do
    let(:workspace) { create(:workspace) }
    let(:user)      { create(:user) }

    before { create(:workspace_membership, workspace: workspace, user: user) }

    it "returns users with a membership" do
      expect(workspace.members).to include(user)
    end
  end
end
