class AddIndexesToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :users, :locked_at,
              where: "locked_at IS NOT NULL",
              name: "idx_users_locked",
              algorithm: :concurrently

    add_index :users, :confirmed_at,
              where: "confirmed_at IS NULL",
              name: "idx_users_unconfirmed",
              algorithm: :concurrently
  end
end
