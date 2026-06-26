# frozen_string_literal: true

class DomainEventJob < ApplicationJob
  queue_as :low

  discard_on ActiveJob::DeserializationError

  def perform(kind:, workspace_id:, actor_id:, subject_type:, subject_id:, metadata:)
    DomainEvent.create!(
      kind:         kind,
      workspace_id: workspace_id,
      actor_id:     actor_id,
      subject_type: subject_type,
      subject_id:   subject_id,
      metadata:     metadata
    )
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordInvalid => e
    Rails.logger.warn("DomainEventJob skipped: #{e.message}")
  rescue ActiveRecord::ConnectionTimeoutError => e
    Rails.logger.warn("DomainEventJob connection timeout: #{e.message}")
  end
end
