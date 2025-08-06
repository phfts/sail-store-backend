class ChangeSoldAtToDate < ActiveRecord::Migration[7.0]
  def up
    # Alterar o tipo da coluna sold_at de datetime para date
    change_column :orders, :sold_at, :date
  end

  def down
    # Reverter para datetime se necessário
    change_column :orders, :sold_at, :datetime
  end
end 