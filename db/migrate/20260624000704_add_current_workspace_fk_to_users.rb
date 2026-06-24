# frozen_string_literal: true

class AddCurrentWorkspaceFkToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :users, :workspaces, column: :current_workspace_id,
                    on_delete: :nullify, validate: false
    validate_foreign_key :users, :workspaces, column: :current_workspace_id
  end
end
