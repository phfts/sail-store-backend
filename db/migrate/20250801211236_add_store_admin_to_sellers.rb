class AddStoreAdminToSellers < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :store_admin, :boolean
  end
end
