class AddStoreIdToGoals < ActiveRecord::Migration[8.0]
  def change
    add_reference :goals, :store, null: true, foreign_key: true
    add_index :goals, [:store_id, :goal_scope]
  end
end
