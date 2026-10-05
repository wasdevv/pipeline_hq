# frozen_string_literal: true

class ChatSession < ApplicationRecord
  REPLY_STALE_AFTER = 2.minutes

  belongs_to :workspace, inverse_of: :chat_sessions
  belongs_to :user, inverse_of: :chat_sessions

  has_many :chat_messages, dependent: :delete_all, inverse_of: :chat_session
  has_many :domain_events, as: :subject, dependent: :nullify

  validate :user_is_workspace_member, on: :create

  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :recent_first, -> { order(updated_at: :desc, id: :desc) }

  def reserve_reply!
    stale = REPLY_STALE_AFTER.ago
    self.class.where(id: id)
      .where("reply_started_at IS NULL OR reply_started_at < ?", stale)
      .update_all(reply_started_at: Time.current, updated_at: Time.current) == 1
  end

  def release_reply!
    update_columns(reply_started_at: nil, updated_at: Time.current)
  end

  def replying?
    reply_started_at.present? && reply_started_at >= REPLY_STALE_AFTER.ago
  end

  def stream_name
    [ self, :chat, user_id ]
  end

  def to_s
    "Assistente ##{id}"
  end

  private

  def user_is_workspace_member
    return if workspace.nil? || user.nil?

    errors.add(:user, :invalid) unless workspace.workspace_memberships.exists?(user_id: user.id)
  end
end
