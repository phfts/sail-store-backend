class AddNotNullConstraintToOrdersExternalId < ActiveRecord::Migration[8.0]
  def change
    # Adicionar constraint NOT NULL para external_id na tabela orders
    change_column_null :orders, :external_id, false
  end
end
