class AddQueueOrderToSellers < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :queue_order, :integer, default: 0
    add_index :sellers, [:store_id, :queue_order]
  end
end
