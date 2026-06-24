# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceMembership, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace).inverse_of(:workspace_memberships) }
    it { is_expected.to belong_to(:user).inverse_of(:workspace_memberships) }
  end

  describe "validations" do
    subject { build(:workspace_membership) }

    it { is_expected.to validate_presence_of(:role) }

    it "rejects duplicate user within the same workspace" do
      membership = create(:workspace_membership)
      duplicate  = build(:workspace_membership, workspace: membership.workspace, user: membership.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user in different workspaces" do
      user = create(:user)
      create(:workspace_membership, user: user)
      second = build(:workspace_membership, user: user)
      expect(second).to be_valid
    end
  end

  describe "enum :role" do
    it { is_expected.to define_enum_for(:role).with_values(owner: 0, admin: 1, member: 2, viewer: 3) }

    it "defaults to :member" do
      membership = WorkspaceMembership.new
      expect(membership.role).to eq("member")
    end

    it "exposes predicate methods for each role" do
      membership = build(:workspace_membership, :owner_role)
      expect(membership).to be_owner
      expect(membership).not_to be_admin
      expect(membership).not_to be_member
      expect(membership).not_to be_viewer
    end

    context "with :admin_role trait" do
      subject { build(:workspace_membership, :admin_role) }

      it { is_expected.to be_admin }
    end

    context "with :viewer_role trait" do
      subject { build(:workspace_membership, :viewer_role) }

      it { is_expected.to be_viewer }
    end
  end

  describe "DB-level uniqueness constraint" do
    it "raises on duplicate (workspace_id, user_id)" do
      m = create(:workspace_membership)
      dup = build(:workspace_membership, workspace: m.workspace, user: m.user)
      expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
