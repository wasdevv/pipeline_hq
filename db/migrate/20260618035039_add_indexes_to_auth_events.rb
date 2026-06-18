class AddIndexesToAuthEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :auth_events, [ :user_id, :created_at ], algorithm: :concurrently
    add_index :auth_events, [ :kind, :created_at ],    algorithm: :concurrently
    add_index :auth_events, :ip_address,             algorithm: :concurrently
    add_index :auth_events, :metadata,
              using: :gin,
              algorithm: :concurrently
  end
end
