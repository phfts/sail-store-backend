class CreateAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :adjustments do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :description, null: false

      t.timestamps
    end
    
    add_index :adjustments, [:seller_id, :created_at]
    add_index :adjustments, [:store_id, :created_at]
    add_index :adjustments, :created_at
  end
end
