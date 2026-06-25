# frozen_string_literal: true

class AddIndexesToWorkspaceMemberships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :workspace_memberships, %i[user_id workspace_id],
              algorithm: :concurrently,
              name: "idx_workspace_memberships_user_workspaces"
  end
end
