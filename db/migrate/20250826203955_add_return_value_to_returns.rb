class AddReturnValueToReturns < ActiveRecord::Migration[8.0]
  def change
    add_column :returns, :return_value, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
