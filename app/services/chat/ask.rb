# frozen_string_literal: true

module Chat
  class Ask
    def self.call(session:, user:, text:) = new(session, user, text).call

    def initialize(session, user, text)
      @session = session
      @user = user
      @text = text.to_s.strip
    end

    def call
      return Result.failure(:blank) if @text.empty?
      return Result.failure(:too_long) if @text.length > ChatMessage::TEXT_MAX
      return Result.failure(:busy) unless @session.reserve_reply!

      enqueue
      record_event
      Result.success(:enqueued, ChatMessage.new(chat_session: @session, role: :user, content: ChatMessage.text_block(@text)))
    end

    private

    def enqueue
      ChatReplyJob.perform_later(
        workspace_id: @session.workspace_id, user_id: @user.id, chat_session_id: @session.id, text: @text
      )
    rescue StandardError
      @session.release_reply!
      raise
    end

    def record_event
      DomainEvents::Record.call(
        kind: "chat.message_sent",
        workspace: @session.workspace,
        actor: @user,
        subject: @session,
        metadata: { chat_session_id: @session.id, text_length: @text.length }
      )
    end
  end
end
