class RemoveExtraFieldsFromCompanies < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:companies, :cnpj)
      remove_column :companies, :cnpj, :string
    end
    
    if column_exists?(:companies, :address)
      remove_column :companies, :address, :text
    end
  end
end
