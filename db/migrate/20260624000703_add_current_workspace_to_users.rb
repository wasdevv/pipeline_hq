# frozen_string_literal: true

class AddCurrentWorkspaceToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :users, :current_workspace, null: true, index: false
  end
end
