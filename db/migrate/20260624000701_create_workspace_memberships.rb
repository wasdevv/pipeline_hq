# frozen_string_literal: true

class CreateWorkspaceMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :workspace_memberships do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role, null: false, default: 2

      t.timestamps
    end

    add_index :workspace_memberships, %i[workspace_id user_id], unique: true,
              name: "idx_workspace_memberships_unique_member"
  end
end
