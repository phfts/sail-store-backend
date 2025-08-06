class AddCompanyIdToSellers < ActiveRecord::Migration[8.0]
  def change
    add_reference :sellers, :company, null: true, foreign_key: true
    add_index :sellers, [:company_id, :external_id], unique: true, where: "company_id IS NOT NULL"
  end
end
