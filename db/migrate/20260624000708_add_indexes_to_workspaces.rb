# frozen_string_literal: true

class AddIndexesToWorkspaces < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :workspaces, :owner_id,
              algorithm: :concurrently,
              name: "idx_workspaces_owner_id"
  end
end
