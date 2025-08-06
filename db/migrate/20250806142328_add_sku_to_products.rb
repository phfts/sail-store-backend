class AddSkuToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :sku, :string
  end
end
