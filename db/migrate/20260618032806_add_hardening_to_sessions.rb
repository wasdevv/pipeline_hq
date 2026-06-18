class AddHardeningToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :last_active_at,  :datetime
    add_column :sessions, :sudo_until,      :datetime
    add_column :sessions, :otp_verified_at, :datetime
  end
end
