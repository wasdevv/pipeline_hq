# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  TEXT_MAX = 2_000

  self.record_timestamps = false

  enum :role, { user: 0, assistant: 1, tool: 2 }, validate: true

  belongs_to :workspace, inverse_of: :chat_messages
  belongs_to :chat_session, inverse_of: :chat_messages

  before_validation :set_defaults, on: :create

  validates :content, presence: true
  validates :tokens_in, :tokens_out, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :workspace_matches_session

  scope :chronological, -> { order(:created_at, :id) }
  scope :visible, -> { where(role: %i[user assistant]) }

  def self.text_block(text)
    [ { "type" => "text", "text" => text.to_s } ]
  end

  def text
    Array(content).filter_map { |block| block["text"] if block["type"] == "text" }.join("\n\n")
  end

  private

  def set_defaults
    self.created_at ||= Time.current
    self.workspace_id ||= chat_session&.workspace_id
  end

  def workspace_matches_session
    return if chat_session.nil?

    errors.add(:workspace, :invalid) unless workspace_id == chat_session.workspace_id
  end
end
