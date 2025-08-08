class AddIsBusyToSellers < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :is_busy, :boolean, default: false
  end
end
