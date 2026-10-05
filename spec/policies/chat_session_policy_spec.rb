# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatSessionPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:workspace) { create(:workspace) }
  let(:user)      { create(:user) }
  let(:record)    { create(:chat_session, user: user, workspace: workspace) }

  before { allow(Current).to receive(:workspace).and_return(workspace) }

  %i[owner admin member viewer].each do |role|
    context "as the session owner with #{role} role" do
      before { create(:workspace_membership, user: user, workspace: workspace, role: role) }

      it { is_expected.to permit_actions(:index, :create, :show, :ask) }
      it { is_expected.to forbid_actions(:update, :destroy) }
    end
  end

  context "when the session belongs to another member of the same workspace" do
    let(:record) do
      peer = create(:user)
      create(:workspace_membership, user: peer, workspace: workspace, role: :member)
      create(:chat_session, user: peer, workspace: workspace)
    end

    before { create(:workspace_membership, user: user, workspace: workspace, role: :admin) }

    it { is_expected.to forbid_actions(:show, :ask) }
  end

  context "when the current workspace is a different one" do
    before do
      create(:workspace_membership, user: user, workspace: workspace, role: :member)
      record
      allow(Current).to receive(:workspace).and_return(user.current_workspace)
    end

    it { is_expected.to forbid_actions(:show, :ask) }
  end

  context "without membership" do
    let(:record) { ChatSession.new(workspace: workspace, user: user) }

    it { is_expected.to forbid_all_actions }
  end

  describe "Scope" do
    it "returns only the user's sessions in the current workspace" do
      create(:workspace_membership, user: user, workspace: workspace, role: :member)
      mine = record
      peer = create(:user)
      create(:workspace_membership, user: peer, workspace: workspace, role: :member)
      create(:chat_session, user: peer, workspace: workspace)
      create(:chat_session, user: user)

      expect(described_class::Scope.new(user, ChatSession).resolve).to contain_exactly(mine)
    end
  end
end
