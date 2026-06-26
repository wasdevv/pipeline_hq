# frozen_string_literal: true

class Conversation < ApplicationRecord
  enum :kind, { direct: 0, group: 1 }, default: :direct, prefix: :kind

  belongs_to :workspace, inverse_of: :conversations

  has_many :participants, class_name: "ConversationParticipant",
           dependent: :destroy, inverse_of: :conversation
  has_many :members, through: :participants, source: :user
  has_many :messages, dependent: :destroy, inverse_of: :conversation

  validates :kind, presence: true

  scope :ordered_by_recent, -> { order(Arel.sql("COALESCE(conversations.last_message_at, conversations.created_at) DESC")) }
  scope :for_user, ->(user) {
    where(id: ConversationParticipant.where(user_id: user.id).select(:conversation_id))
  }

  def participant_for(user)
    participants.find_by(user_id: user.id)
  end

  def other_member_for(user)
    members.find { |m| m.id != user.id }
  end

  def self.direct_signature_for(users)
    users.map(&:id).sort.join("-")
  end
end
