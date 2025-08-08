class AddScopeTypeToGoals < ActiveRecord::Migration[8.0]
  def change
    add_column :goals, :scope_type, :integer
  end
end
