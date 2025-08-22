class AddStoreIdToOrders < ActiveRecord::Migration[8.0]
  def up
    # Primeiro adicionar a coluna como nullable
    add_reference :orders, :store, null: true, foreign_key: true
    
    # Popular o store_id baseado no seller.store_id
    execute <<-SQL
      UPDATE orders 
      SET store_id = sellers.store_id 
      FROM sellers 
      WHERE orders.seller_id = sellers.id
    SQL
    
    # Agora tornar a coluna obrigatória
    change_column_null :orders, :store_id, false
    
    # Adicionar índice único para external_id por loja
    add_index :orders, [:store_id, :external_id], unique: true, where: "external_id IS NOT NULL"
  end
  
  def down
    remove_index :orders, [:store_id, :external_id]
    remove_reference :orders, :store, foreign_key: true
  end
end
