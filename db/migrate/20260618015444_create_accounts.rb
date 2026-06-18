class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, limit: 120
      t.string :industry
      t.string :website
      t.text :notes

      t.timestamps
    end
    add_index :accounts, :name
  end
end
