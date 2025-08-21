class AddUniqueIndexToOrdersExternalIdByStore < ActiveRecord::Migration[8.0]
  def change
    # Remover o índice único global se existir
    remove_index :orders, :external_id, if_exists: true
    
    # Adicionar índice único por store (através do seller)
    add_index :orders, [:seller_id, :external_id], unique: true, where: "external_id IS NOT NULL", name: "index_orders_on_seller_id_and_external_id_unique"
  end
end
