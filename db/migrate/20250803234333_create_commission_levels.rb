class CreateCommissionLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_levels do |t|
      t.references :store, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :achievement_percentage, precision: 5, scale: 2, null: false
      t.decimal :commission_percentage, precision: 5, scale: 2, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :commission_levels, [:store_id, :achievement_percentage], unique: true
  end
end
