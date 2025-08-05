class AddExternalIdToSellers < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :external_id, :string
  end
end
