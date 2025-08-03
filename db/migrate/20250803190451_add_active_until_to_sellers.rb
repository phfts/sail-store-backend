class AddActiveUntilToSellers < ActiveRecord::Migration[8.0]
  def change
    add_column :sellers, :active_until, :datetime
  end
end
