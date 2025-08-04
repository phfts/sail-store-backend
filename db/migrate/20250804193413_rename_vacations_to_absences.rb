class RenameVacationsToAbsences < ActiveRecord::Migration[8.0]
  def change
    rename_table :vacations, :absences
  end
end
