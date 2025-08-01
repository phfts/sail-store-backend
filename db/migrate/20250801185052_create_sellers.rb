class CreateSellers < ActiveRecord::Migration[8.0]
  def change
    create_table :sellers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :whatsapp
      t.string :email

      t.timestamps
    end
  end
end
