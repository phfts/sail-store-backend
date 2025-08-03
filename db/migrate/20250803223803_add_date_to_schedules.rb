class AddDateToSchedules < ActiveRecord::Migration[8.0]
  def up
    # Adicionar o novo campo date
    add_column :schedules, :date, :date
    
    # Migrar dados existentes
    Schedule.find_each do |schedule|
      # Calcular a data baseada nos campos antigos
      calculated_date = Date.commercial(schedule.year, schedule.week_number, schedule.day_of_week + 1)
      schedule.update_column(:date, calculated_date)
    end
    
    # Remover os campos antigos
    remove_column :schedules, :day_of_week
    remove_column :schedules, :week_number
    remove_column :schedules, :year
  end
  
  def down
    # Adicionar os campos antigos de volta
    add_column :schedules, :day_of_week, :integer
    add_column :schedules, :week_number, :integer
    add_column :schedules, :year, :integer
    
    # Migrar dados de volta (aproximado)
    Schedule.find_each do |schedule|
      if schedule.date
        schedule.update_column(:day_of_week, schedule.date.wday)
        schedule.update_column(:week_number, schedule.date.cweek)
        schedule.update_column(:year, schedule.date.year)
      end
    end
    
    # Remover o campo date
    remove_column :schedules, :date
  end
end
