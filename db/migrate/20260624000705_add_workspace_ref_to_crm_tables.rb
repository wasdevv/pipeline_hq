# frozen_string_literal: true

class AddWorkspaceRefToCrmTables < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :accounts,   :workspace, null: true, index: false
    add_reference :contacts,   :workspace, null: true, index: false
    add_reference :stages,     :workspace, null: true, index: false
    add_reference :deals,      :workspace, null: true, index: false
    add_reference :activities, :workspace, null: true, index: false
  end
end
