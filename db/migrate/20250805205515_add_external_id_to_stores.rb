class AddExternalIdToStores < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :external_id, :string
  end
end
