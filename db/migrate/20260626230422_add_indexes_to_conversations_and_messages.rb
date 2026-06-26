# frozen_string_literal: true

class AddIndexesToConversationsAndMessages < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :conversations,
              %i[workspace_id last_message_at],
              order: { last_message_at: :desc },
              name: "idx_conversations_workspace_last_message_at",
              algorithm: :concurrently

    add_index :conversations,
              %i[workspace_id participants_signature],
              unique: true,
              where: "kind = 0 AND participants_signature IS NOT NULL",
              name: "idx_conversations_direct_signature_unique",
              algorithm: :concurrently

    add_index :conversation_participants,
              %i[conversation_id user_id],
              unique: true,
              name: "idx_conversation_participants_unique",
              algorithm: :concurrently

    add_index :conversation_participants,
              %i[user_id last_read_at],
              name: "idx_conversation_participants_user_last_read_at",
              algorithm: :concurrently

    add_index :messages,
              %i[conversation_id created_at],
              order: { created_at: :asc },
              name: "idx_messages_conversation_created_at",
              algorithm: :concurrently
  end
end
