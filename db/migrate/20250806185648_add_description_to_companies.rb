class AddDescriptionToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :description, :text
  end
end
