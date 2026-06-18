class AddHardeningToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name,                  :string
    add_column :users, :confirmed_at,          :datetime
    add_column :users, :confirmation_sent_at,  :datetime
    add_column :users, :failed_attempts,       :integer, null: false, default: 0
    add_column :users, :locked_at,             :datetime
    add_column :users, :otp_secret,            :string
    add_column :users, :otp_enabled_at,        :datetime
    add_column :users, :otp_backup_codes,      :string, array: true, null: false, default: []
  end
end
