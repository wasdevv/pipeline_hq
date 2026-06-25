# frozen_string_literal: true

class AddWorkspaceFksToCrmTables < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  CRM_TABLES = %i[accounts contacts stages deals activities].freeze

  def up
    CRM_TABLES.each do |table|
      add_foreign_key table, :workspaces, column: :workspace_id,
                      on_delete: :cascade, validate: false
    end
    CRM_TABLES.each do |table|
      validate_foreign_key table, :workspaces, column: :workspace_id
    end
  end

  def down
    CRM_TABLES.each do |table|
      remove_foreign_key table, :workspaces, column: :workspace_id
    end
  end
end
