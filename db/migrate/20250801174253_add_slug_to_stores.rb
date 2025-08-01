class AddSlugToStores < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :slug, :string
  end
end
