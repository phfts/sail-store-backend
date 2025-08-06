class AddExternalIdToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :external_id, :string
  end
end
