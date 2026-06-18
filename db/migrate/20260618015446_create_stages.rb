class CreateStages < ActiveRecord::Migration[8.1]
  def change
    create_table :stages do |t|
      t.string :name, limit: 60
      t.integer :position
      t.string :color

      t.timestamps
    end
    add_index :stages, :position
  end
end
