class AddNameToSellersAndMakeUserIdOptional < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :name, :string
    
    # Tornar user_id opcional
    change_column_null :sellers, :user_id, true
    
    # Adicionar validação para garantir que pelo menos name ou user_id esteja presente
    add_index :sellers, [:name, :user_id], unique: true, where: "name IS NOT NULL AND user_id IS NOT NULL"
  end
end
