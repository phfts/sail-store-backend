class RemoveSalesTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :sales
  end
end
