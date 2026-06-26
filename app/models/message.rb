# frozen_string_literal: true

class Message < ApplicationRecord
  BODY_MAX = 4_000

  self.record_timestamps = false

  belongs_to :conversation, inverse_of: :messages, counter_cache: false
  belongs_to :sender, class_name: "User", optional: true, inverse_of: :sent_messages

  before_validation :set_created_at, on: :create
  after_create_commit :broadcast_to_conversation

  validates :body, presence: true, length: { maximum: BODY_MAX }
  validates :created_at, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  private

  def broadcast_to_conversation
    conversation.participants.where.not(user_id: sender_id).find_each do |participant|
      broadcast_append_later_to(
        [ conversation, :messages, participant.user_id ],
        target: ActionView::RecordIdentifier.dom_id(conversation, :messages),
        partial: "messages/message",
        locals: { message: self, current_user_id: participant.user_id }
      )
    end
  end

  private

  def set_created_at
    self.created_at ||= Time.current
  end
end
