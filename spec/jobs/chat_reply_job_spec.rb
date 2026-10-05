# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatReplyJob, type: :job do
  include ActionCable::TestHelper

  let(:session) { create(:chat_session) }
  let(:stream)  { Turbo::StreamsChannel.send(:stream_name_from, session.stream_name) }

  def perform(**overrides)
    described_class.perform_now(
      workspace_id: session.workspace_id, user_id: session.user_id, chat_session_id: session.id,
      text: "Quantos negócios abertos?", **overrides
    )
  end

  before { session.reserve_reply! }

  it "broadcasts the answer to the session stream, clears the indicator and releases the session" do
    stub_anthropic(anthropic_ok(anthropic_text("Você tem 3 negócios abertos.")))

    expect { perform }.to have_broadcasted_to(stream).with { |payload|
      expect(payload).to include("Você tem 3 negócios abertos.").or include(%(action="remove"))
    }.exactly(2).times

    expect(session.reload).not_to be_replying
  end

  it "turns a 429 into a friendly message in the conversation without raising" do
    stub_anthropic(anthropic_error(429, "rate_limit_error"))

    expect { perform }.not_to raise_error

    expect(session.chat_messages.chronological.last).to have_attributes(role: "assistant", text: I18n.t("chat.errors.rate_limited"))
    expect(broadcasts(stream).join).to include(ERB::Util.html_escape(I18n.t("chat.errors.rate_limited")))
    expect(session.reload).not_to be_replying
  end

  it "posts a generic message, releases the session and re-raises on an unexpected error" do
    allow(Chat::Reply).to receive(:call).and_raise(ActiveRecord::ConnectionTimeoutError)

    expect { perform }.to raise_error(ActiveRecord::ConnectionTimeoutError)
    expect(session.chat_messages.last.text).to eq(I18n.t("chat.errors.api_error"))
    expect(session.reload).not_to be_replying
  end

  it "does nothing when the user is no longer a member of the workspace" do
    session.workspace.workspace_memberships.where(user_id: session.user_id).delete_all
    stub_anthropic(anthropic_ok(anthropic_text("não deveria")))

    perform

    expect(anthropic_bodies).to be_empty
    expect(session.chat_messages).to be_empty
  end

  it "ignores a session id that belongs to another workspace" do
    other = create(:chat_session)
    stub_anthropic(anthropic_ok(anthropic_text("não deveria")))

    perform(chat_session_id: other.id)

    expect(anthropic_bodies).to be_empty
    expect(other.chat_messages).to be_empty
  end
end
