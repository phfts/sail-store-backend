class AddCompanyIdToStores < ActiveRecord::Migration[8.0]
  def change
    add_reference :stores, :company, null: true, foreign_key: true
  end
end
