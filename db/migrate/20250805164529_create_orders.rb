class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :external_id
      t.references :seller, null: false, foreign_key: true

      t.timestamps
    end
  end
end
