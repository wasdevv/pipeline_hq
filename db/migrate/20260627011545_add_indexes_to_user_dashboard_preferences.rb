# frozen_string_literal: true

class AddIndexesToUserDashboardPreferences < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :user_dashboard_preferences,
              %i[user_id section],
              unique: true,
              name: "idx_user_dashboard_preferences_unique",
              algorithm: :concurrently

    add_index :user_dashboard_preferences,
              %i[user_id position],
              name: "idx_user_dashboard_preferences_position",
              algorithm: :concurrently
  end
end
