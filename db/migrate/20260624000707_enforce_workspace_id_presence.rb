# frozen_string_literal: true

class EnforceWorkspaceIdPresence < ActiveRecord::Migration[8.1]
  TABLES = %i[accounts contacts stages deals activities].freeze

  def up
    TABLES.each do |table|
      null_count = safety_assured { execute("SELECT COUNT(*) FROM #{table} WHERE workspace_id IS NULL").first["count"].to_i }
      raise "Run `bin/rails workspace:backfill` before this migration — #{null_count} rows in #{table} still have workspace_id NULL." if null_count > 0

      safety_assured { change_column_null table, :workspace_id, false }
    end
  end

  def down
    TABLES.each do |table|
      safety_assured { change_column_null table, :workspace_id, true }
    end
  end
end
