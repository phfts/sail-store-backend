class CreateReturns < ActiveRecord::Migration[8.0]
  def change
    create_table :returns do |t|
      t.string :external_id
      t.string :original_sale_id
      t.string :product_external_id
      t.string :original_transaction
      t.string :return_transaction
      t.decimal :quantity_returned
      t.datetime :processed_at
      t.references :original_order, null: true, foreign_key: { to_table: :orders }
      t.references :product, null: true, foreign_key: true

      t.timestamps
    end
    add_index :returns, :external_id, unique: true
  end
end
