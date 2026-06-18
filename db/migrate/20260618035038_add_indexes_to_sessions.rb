class AddIndexesToSessions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :sessions, [ :user_id, :last_active_at ], algorithm: :concurrently
  end
end
