class AddStoreAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :store_admin, :boolean, default: false, null: false
    add_index :users, :store_admin
  end
end
