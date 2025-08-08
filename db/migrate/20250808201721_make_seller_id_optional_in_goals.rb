class MakeSellerIdOptionalInGoals < ActiveRecord::Migration[8.0]
  def change
    change_column_null :goals, :seller_id, true
  end
end
