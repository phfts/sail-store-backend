class RenameScopeTypeToGoalScope < ActiveRecord::Migration[8.0]
  def change
    rename_column :goals, :scope_type, :goal_scope
  end
end
