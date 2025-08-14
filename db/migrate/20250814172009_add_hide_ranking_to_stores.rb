class AddHideRankingToStores < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :hide_ranking, :boolean, default: false, null: false
  end
end
