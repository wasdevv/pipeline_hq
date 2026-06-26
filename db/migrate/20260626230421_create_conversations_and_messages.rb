# frozen_string_literal: true

class CreateConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.integer :kind, null: false, default: 0
      t.string :participants_signature
      t.datetime :last_message_at
      t.timestamps
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :last_read_at
      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :sender, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.text :body, null: false
      t.datetime :created_at, null: false
    end
  end
end
