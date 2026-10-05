# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Chat sessions", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }

  before { perform_enqueued_jobs { sign_in_as(user) } }

  describe "GET /chat_sessions" do
    it "renders the panel with the latest session and its history inside the chat frame" do
      session = create(:chat_session, user: user, workspace: workspace)
      create(:chat_message, chat_session: session, content: ChatMessage.text_block("Pergunta antiga"))
      create(:chat_message, chat_session: session, role: :tool,
                            content: [ { "type" => "tool_result", "tool_use_id" => "t", "content" => "{\"secret\":1}" } ])

      get chat_sessions_path, headers: { "Turbo-Frame" => "chat_panel" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="chat_panel"), "Pergunta antiga")
      expect(response.body).not_to include("secret")
    end

    it "offers to start a conversation when there is none" do
      get chat_sessions_path

      expect(response.body).to include(I18n.t("chat.panel.new_session"))
    end
  end

  describe "POST /chat_sessions" do
    it "creates a session for the current user in the current workspace" do
      expect { post chat_sessions_path }.to change(workspace.chat_sessions.where(user: user), :count).by(1)

      expect(response).to redirect_to(chat_session_path(ChatSession.last))
    end
  end

  describe "GET /chat_sessions/:id" do
    it "returns 404 for a session of another workspace" do
      get chat_session_path(create(:chat_session))

      expect(response).to have_http_status(:not_found)
    end

    it "subscribes to a stream scoped to the session and its owner" do
      session = create(:chat_session, user: user, workspace: workspace)

      get chat_session_path(session)

      signed = Turbo::StreamsChannel.signed_stream_name(session.stream_name)
      expect(response.body).to include(%(signed-stream-name="#{signed}"))
    end
  end
end
