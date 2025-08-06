class AddCompanyIdToCategories < ActiveRecord::Migration[8.0]
  def change
    add_reference :categories, :company, null: true, foreign_key: true
    add_index :categories, [:company_id, :external_id], unique: true, where: "company_id IS NOT NULL"
  end
end
