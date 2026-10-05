# frozen_string_literal: true

class ChatReplyJob < ApplicationJob
  queue_as :default

  def perform(workspace_id:, user_id:, chat_session_id:, text:)
    session = authorized_session(workspace_id, user_id, chat_session_id)
    return unless session

    begin
      result = Chat::Reply.call(session: session, text: text)
      broadcast_message(session, result.payload) if result.payload
    rescue StandardError
      broadcast_message(session, session.chat_messages.create!(
        role: :assistant, content: ChatMessage.text_block(I18n.t("chat.errors.api_error"))
      ))
      raise
    ensure
      session.release_reply!
      Turbo::StreamsChannel.broadcast_remove_to(session.stream_name, target: ActionView::RecordIdentifier.dom_id(session, :thinking))
    end
  end

  private

  def authorized_session(workspace_id, user_id, chat_session_id)
    workspace = Workspace.find_by(id: workspace_id)
    return unless workspace&.workspace_memberships&.exists?(user_id: user_id)

    workspace.chat_sessions.find_by(id: chat_session_id, user_id: user_id)
  end

  def broadcast_message(session, message)
    Turbo::StreamsChannel.broadcast_append_to(
      session.stream_name,
      target: ActionView::RecordIdentifier.dom_id(session, :messages),
      partial: "chat_messages/message",
      locals: { message: message }
    )
  end
end
