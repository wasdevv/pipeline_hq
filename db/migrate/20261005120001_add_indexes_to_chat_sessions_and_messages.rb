# frozen_string_literal: true

class AddIndexesToChatSessionsAndMessages < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :chat_sessions, %i[workspace_id user_id updated_at],
              name: "idx_chat_sessions_workspace_user_updated_at",
              algorithm: :concurrently
    add_index :chat_sessions, :user_id, algorithm: :concurrently

    add_index :chat_messages, %i[chat_session_id created_at],
              name: "idx_chat_messages_session_created_at",
              algorithm: :concurrently
    add_index :chat_messages, %i[workspace_id created_at],
              name: "idx_chat_messages_workspace_created_at",
              algorithm: :concurrently
  end
end
