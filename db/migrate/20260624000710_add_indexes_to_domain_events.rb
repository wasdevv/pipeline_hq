# frozen_string_literal: true

class AddIndexesToDomainEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :domain_events, %i[workspace_id created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "idx_domain_events_workspace_created_at"

    add_index :domain_events, %i[workspace_id kind created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "idx_domain_events_workspace_kind_created_at"

    add_index :domain_events, %i[subject_type subject_id],
              algorithm: :concurrently,
              name: "idx_domain_events_subject"

    add_index :domain_events, :metadata,
              using: :gin,
              algorithm: :concurrently,
              name: "idx_domain_events_metadata_gin"
  end
end
