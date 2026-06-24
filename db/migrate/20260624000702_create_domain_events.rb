# frozen_string_literal: true

class CreateDomainEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :domain_events do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :kind, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end
  end
end
