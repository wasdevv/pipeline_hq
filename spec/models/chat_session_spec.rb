# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatSession, type: :model do
  subject(:session) { create(:chat_session) }

  it { is_expected.to belong_to(:workspace) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:chat_messages).dependent(:delete_all) }

  it "requires the user to be a member of the workspace" do
    outsider = build(:chat_session, workspace: create(:workspace))

    expect(outsider).not_to be_valid
    expect(outsider.errors[:user]).to be_present
  end

  describe "reply reservation" do
    it "reserves once until released" do
      expect(session.reserve_reply!).to be(true)
      expect(session.reload).to be_replying
      expect(session.reserve_reply!).to be(false)

      session.release_reply!

      expect(session.reload).not_to be_replying
      expect(session.reserve_reply!).to be(true)
    end

    it "takes over a reservation older than the stale window" do
      session.update_columns(reply_started_at: (ChatSession::REPLY_STALE_AFTER + 1.second).ago)

      expect(session).not_to be_replying
      expect(session.reserve_reply!).to be(true)
    end
  end

  it "streams on a name that includes the owner" do
    expect(session.stream_name).to eq([ session, :chat, session.user_id ])
  end
end
