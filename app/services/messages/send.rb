# frozen_string_literal: true

module Messages
  class Send
    def self.call(conversation:, sender:, body:)
      new(conversation, sender, body).call
    end

    def initialize(conversation, sender, body)
      @conversation = conversation
      @sender = sender
      @body = body.to_s.strip
    end

    def call
      return Result.failure(:blank)           if @body.empty?
      return Result.failure(:not_participant) unless participant?

      message = create_message
      DomainEvents::Record.call(
        kind: "direct_message_sent",
        workspace: @conversation.workspace,
        actor: @sender,
        subject: @conversation,
        metadata: { message_id: message.id, body_length: @body.length }
      )
      Result.success(:sent, message)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(:invalid, e.record.errors)
    end

    private

    def participant?
      @conversation.participants.exists?(user_id: @sender.id)
    end

    def create_message
      Message.transaction do
        message = @conversation.messages.create!(sender: @sender, body: @body)
        @conversation.update_columns(last_message_at: message.created_at, updated_at: Time.current)
        message
      end
    end
  end
end
