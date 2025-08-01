class MakeStoreIdRequiredInSellers < ActiveRecord::Migration[8.0]
  def up
    # Primeiro, garantir que todos os sellers tenham um store_id
    store = Store.first
    if store
      Seller.where(store_id: nil).update_all(store_id: store.id)
    end
    
    # Depois tornar a coluna obrigatória
    change_column_null :sellers, :store_id, false
  end

  def down
    change_column_null :sellers, :store_id, true
  end
end
