# frozen_string_literal: true

class CreateWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users, on_delete: :restrict }

      t.timestamps
    end

    add_index :workspaces, :slug, unique: true
  end
end
