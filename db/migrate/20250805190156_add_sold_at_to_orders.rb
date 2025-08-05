class AddSoldAtToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :sold_at, :datetime
  end
end
