class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :companies, :slug, unique: true
  end
end
