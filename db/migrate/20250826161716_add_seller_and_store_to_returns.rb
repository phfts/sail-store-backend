class AddSellerAndStoreToReturns < ActiveRecord::Migration[8.0]
  def change
    add_reference :returns, :seller, null: true, foreign_key: true
    add_reference :returns, :store, null: true, foreign_key: true
    
    # Como não temos original_order_id, vamos definir valores padrão
    # ou deixar como null por enquanto
  end
end
