class AddDescriptionToCompanies < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:companies, :description)
      add_column :companies, :description, :text
    end
  end
end
