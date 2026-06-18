class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :deal, null: false, foreign_key: true
      t.string :kind, limit: 30
      t.string :subject, limit: 160
      t.text :body
      t.datetime :occurred_at

      t.timestamps
    end
    add_index :activities, :kind
    add_index :activities, :occurred_at
  end
end
