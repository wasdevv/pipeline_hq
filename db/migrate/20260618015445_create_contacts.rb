class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, limit: 120
      t.string :email
      t.string :phone
      t.string :role

      t.timestamps
    end
    add_index :contacts, :email
  end
end
