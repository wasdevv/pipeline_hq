# frozen_string_literal: true

class AddIndexesToCrmWorkspaceColumns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :accounts, %i[workspace_id created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "idx_accounts_workspace_created_at"

    add_index :contacts, %i[workspace_id account_id],
              algorithm: :concurrently,
              name: "idx_contacts_workspace_account"

    add_index :contacts, %i[workspace_id created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "idx_contacts_workspace_created_at"

    add_index :stages, %i[workspace_id position],
              unique: true,
              algorithm: :concurrently,
              name: "idx_stages_workspace_position_unique"

    add_index :deals, %i[workspace_id stage_id],
              algorithm: :concurrently,
              name: "idx_deals_workspace_stage"

    add_index :deals, %i[workspace_id created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "idx_deals_workspace_created_at"

    add_index :activities, %i[workspace_id deal_id occurred_at],
              order: { occurred_at: :desc },
              algorithm: :concurrently,
              name: "idx_activities_workspace_deal_occurred_at"
  end
end
