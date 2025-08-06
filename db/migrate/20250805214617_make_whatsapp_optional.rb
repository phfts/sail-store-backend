class MakeWhatsappOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :sellers, :whatsapp, true
  end
end
