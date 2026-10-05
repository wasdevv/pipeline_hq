# frozen_string_literal: true

class CreateChatSessionsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions do |t|
      t.references :workspace, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.datetime :reply_started_at
      t.timestamps
    end

    create_table :chat_messages do |t|
      t.references :workspace, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :chat_session, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.integer :role, null: false
      t.jsonb :content, null: false, default: []
      t.integer :tokens_in, null: false, default: 0
      t.integer :tokens_out, null: false, default: 0
      t.datetime :created_at, null: false
      t.check_constraint "role IN (0, 1, 2)", name: "chat_messages_role_check"
      t.check_constraint "tokens_in >= 0 AND tokens_out >= 0", name: "chat_messages_tokens_check"
      t.check_constraint "jsonb_typeof(content) = 'array'", name: "chat_messages_content_array_check"
    end
  end
end
