class AddStoreIdToSellers < ActiveRecord::Migration[8.0]
  def change
    add_reference :sellers, :store, null: true, foreign_key: true
  end
end
