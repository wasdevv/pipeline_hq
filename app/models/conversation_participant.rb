# frozen_string_literal: true

class ConversationParticipant < ApplicationRecord
  belongs_to :conversation, inverse_of: :participants
  belongs_to :user, inverse_of: :conversation_participants

  validates :user_id, uniqueness: { scope: :conversation_id }

  scope :unread_for, ->(user) {
    where(user_id: user.id).joins(conversation: :messages)
      .where("messages.sender_id != ? AND messages.created_at > COALESCE(conversation_participants.last_read_at, '1970-01-01')", user.id)
      .distinct
  }

  def unread_count
    base = conversation.messages.where.not(sender_id: user_id)
    return base.count if last_read_at.nil?

    base.where("created_at > ?", last_read_at).count
  end
end
