class CreateDeals < ActiveRecord::Migration[8.1]
  def change
    create_table :deals do |t|
      t.string :title, limit: 160
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :currency
      t.date :expected_close_on
      t.string :status

      t.timestamps
    end
    add_index :deals, :status
  end
end
