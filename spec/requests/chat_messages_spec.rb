# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Chat messages", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:session)   { create(:chat_session, user: user, workspace: workspace) }
  let(:turbo)     { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    perform_enqueued_jobs { sign_in_as(user) }
  end

  def ask(text = "Quais negócios fecham este mês?", chat_session: session)
    post chat_session_chat_messages_path(chat_session), params: { chat_message: { text: text } }, headers: turbo
  end

  it "enqueues one reply job with server-side ids and answers with a Turbo Stream" do
    expect { ask }.to have_enqueued_job(ChatReplyJob).exactly(:once).with(
      workspace_id: workspace.id, user_id: user.id, chat_session_id: session.id, text: "Quais negócios fecham este mês?"
    )

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include(%(<turbo-stream action="append" target="#{ActionView::RecordIdentifier.dom_id(session, :messages)}"))
    expect(response.body).to include("Quais negócios fecham este mês?", I18n.t("chat.panel.thinking"))
    expect(session.reload).to be_replying
  end

  it "records a chat.message_sent domain event without the question text" do
    expect { ask }.to have_enqueued_job(DomainEventJob).with(
      hash_including(kind: "chat.message_sent", actor_id: user.id, workspace_id: workspace.id,
                     metadata: { chat_session_id: session.id, text_length: 31 })
    )
  end

  it "ignores a workspace_id sent by the client" do
    other = create(:workspace)

    expect {
      post chat_session_chat_messages_path(session), params: { chat_message: { text: "oi", workspace_id: other.id }, workspace_id: other.id }, headers: turbo
    }.to have_enqueued_job(ChatReplyJob).with(hash_including(workspace_id: workspace.id))
  end

  it "rejects blank text with a friendly error" do
    expect { ask("   ") }.not_to have_enqueued_job(ChatReplyJob)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("chat.errors.blank"))
  end

  it "refuses a second question while the first is being answered" do
    ask
    expect { ask("outra") }.not_to have_enqueued_job(ChatReplyJob)

    expect(response).to have_http_status(:conflict)
    expect(response.body).to include(I18n.t("chat.errors.busy"))
  end

  it "returns 404 for a session of another workspace" do
    foreign = create(:chat_session)

    expect { ask(chat_session: foreign) }.not_to have_enqueued_job(ChatReplyJob)
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for another member's session in the same workspace" do
    peer = create(:user)
    create(:workspace_membership, user: peer, workspace: workspace, role: :member)
    peers_session = create(:chat_session, user: peer, workspace: workspace)

    expect { ask(chat_session: peers_session) }.not_to have_enqueued_job(ChatReplyJob)
    expect(response).to have_http_status(:not_found)
  end

  it "lets a viewer ask (read-only feature)" do
    viewer = create(:user)
    create(:workspace_membership, user: viewer, workspace: workspace, role: :viewer)
    viewer.update_columns(current_workspace_id: workspace.id)
    viewer_session = create(:chat_session, user: viewer, workspace: workspace)
    delete session_path
    perform_enqueued_jobs { sign_in_as(viewer) }

    expect { ask(chat_session: viewer_session) }.to have_enqueued_job(ChatReplyJob)
  end

  it "requires authentication" do
    delete session_path

    ask

    expect(response).to redirect_to(new_session_path)
  end

  describe "per-user rate limit" do
    it "throttles after #{ChatMessagesController::RATE_LIMIT} questions per minute, per user" do
      ChatMessagesController::RATE_LIMIT.times do
        session.release_reply!
        ask
      end
      session.release_reply!
      ask

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t("chat.errors.throttled"))
    end

    it "counts each user separately even from the same IP" do
      ChatMessagesController::RATE_LIMIT.times do
        session.release_reply!
        ask
      end

      peer = create(:user)
      peer_session = create(:chat_session, user: peer)
      delete session_path
      perform_enqueued_jobs { sign_in_as(peer) }

      expect { ask(chat_session: peer_session) }.to have_enqueued_job(ChatReplyJob)
    end

    it "resets after the window" do
      ChatMessagesController::RATE_LIMIT.times do
        session.release_reply!
        ask
      end

      travel(ChatMessagesController::RATE_WINDOW + 1.second) do
        session.release_reply!
        expect { ask }.to have_enqueued_job(ChatReplyJob)
      end
    end
  end
end
