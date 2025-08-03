class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :seller, null: false, foreign_key: true
      t.decimal :value, null: false, precision: 10, scale: 2
      t.datetime :sold_at, null: false

      t.timestamps
    end
  end
end
