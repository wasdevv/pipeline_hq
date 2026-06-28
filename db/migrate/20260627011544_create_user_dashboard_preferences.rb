# frozen_string_literal: true

class CreateUserDashboardPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_dashboard_preferences do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :section, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
