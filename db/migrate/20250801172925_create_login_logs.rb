class CreateLoginLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :login_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :login_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
