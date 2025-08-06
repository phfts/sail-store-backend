class MakeCompanyIdRequired < ActiveRecord::Migration[8.0]
  def change
    # Tornar company_id obrigatório em sellers
    change_column_null :sellers, :company_id, false
    
    # Tornar company_id obrigatório em categories
    change_column_null :categories, :company_id, false
    
    # Tornar company_id obrigatório em stores
    change_column_null :stores, :company_id, false
  end
end
