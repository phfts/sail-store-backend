class CreateExchanges < ActiveRecord::Migration[8.0]
  def change
    create_table :exchanges do |t|
      t.string :external_id
      t.string :voucher_number
      t.decimal :voucher_value
      t.string :original_document
      t.string :new_document
      t.string :customer_code
      t.string :exchange_type
      t.boolean :is_credit
      t.datetime :processed_at
      t.references :seller, null: true, foreign_key: true
      t.references :original_order, null: true, foreign_key: { to_table: :orders }
      t.references :new_order, null: true, foreign_key: { to_table: :orders }

      t.timestamps
    end
    add_index :exchanges, :external_id, unique: true
  end
end
