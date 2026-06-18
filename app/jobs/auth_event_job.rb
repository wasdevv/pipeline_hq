# frozen_string_literal: true

class AuthEventJob < ApplicationJob
  queue_as :low

  discard_on ActiveJob::DeserializationError

  def perform(kind:, user_id:, email_address:, ip_address:, user_agent:, metadata:)
    AuthEvent.create!(
      kind:          kind,
      user_id:       user_id,
      email_address: email_address,
      ip_address:    ip_address,
      user_agent:    user_agent,
      metadata:      metadata
    )
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordInvalid => e
    Rails.logger.warn("AuthEventJob skipped: #{e.message}")
  end
end
