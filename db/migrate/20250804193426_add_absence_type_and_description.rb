class AddAbsenceTypeAndDescription < ActiveRecord::Migration[8.0]
  def change
    add_column :absences, :absence_type, :string, default: 'vacation'
    add_column :absences, :description, :text
    
    # Índice para melhor performance
    add_index :absences, :absence_type
  end
end
