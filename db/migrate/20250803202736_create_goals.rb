class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :goals do |t|
      t.references :seller, null: false, foreign_key: true
      t.integer :goal_type
      t.date :start_date
      t.date :end_date
      t.decimal :target_value
      t.decimal :current_value
      t.text :description

      t.timestamps
    end
  end
end
