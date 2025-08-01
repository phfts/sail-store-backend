class RenameUsernameToName < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :username, :name
  end
end
