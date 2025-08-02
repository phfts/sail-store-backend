class CreateVacations < ActiveRecord::Migration[8.0]
  def change
    create_table :vacations do |t|
      t.references :seller, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.text :reason

      t.timestamps
    end
  end
end
