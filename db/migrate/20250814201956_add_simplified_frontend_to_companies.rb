class AddSimplifiedFrontendToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :simplified_frontend, :boolean, default: false, null: false
  end
end
