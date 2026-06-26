# frozen_string_literal: true

module DomainEvents
  class Record
    def self.call(kind:, workspace:, actor: nil, subject: nil, metadata: {})
      DomainEventJob.perform_later(
        kind:         kind.to_s,
        workspace_id: workspace.id,
        actor_id:     actor&.id,
        subject_type: subject&.class&.name,
        subject_id:   subject&.id,
        metadata:     metadata
      )
    end
  end
end
