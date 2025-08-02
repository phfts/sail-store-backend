class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.references :seller, null: false, foreign_key: true
      t.references :shift, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.integer :day_of_week
      t.integer :week_number
      t.integer :year

      t.timestamps
    end
  end
end
