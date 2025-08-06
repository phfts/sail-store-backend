class AddSlugToCompanies < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:companies, :slug)
      add_column :companies, :slug, :string
      add_index :companies, :slug, unique: true
    end
  end
end
