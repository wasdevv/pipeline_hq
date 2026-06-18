class CreateAuthEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_events do |t|
      t.references :user, foreign_key: true
      t.string     :email_address
      t.string     :kind, null: false
      t.string     :ip_address
      t.string     :user_agent
      t.jsonb      :metadata, null: false, default: {}
      t.datetime   :created_at, null: false
    end
  end
end
