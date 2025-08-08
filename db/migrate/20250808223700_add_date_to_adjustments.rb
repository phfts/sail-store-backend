class AddDateToAdjustments < ActiveRecord::Migration[8.0]
  def change
    add_column :adjustments, :date, :date, default: -> { 'CURRENT_DATE' }
  end
end
