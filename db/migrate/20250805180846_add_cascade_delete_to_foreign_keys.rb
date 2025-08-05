class AddCascadeDeleteToForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys existentes
    remove_foreign_key :absences, :sellers
    remove_foreign_key :commission_levels, :stores
    remove_foreign_key :goals, :sellers
    remove_foreign_key :login_logs, :users
    remove_foreign_key :order_items, :orders
    remove_foreign_key :order_items, :products
    remove_foreign_key :orders, :sellers
    remove_foreign_key :products, :categories
    remove_foreign_key :sales, :sellers
    remove_foreign_key :schedules, :sellers
    remove_foreign_key :schedules, :shifts
    remove_foreign_key :schedules, :stores
    remove_foreign_key :sellers, :stores
    remove_foreign_key :sellers, :users
    remove_foreign_key :shifts, :stores

    # Adiciona foreign keys com CASCADE DELETE
    add_foreign_key :absences, :sellers, on_delete: :cascade
    add_foreign_key :commission_levels, :stores, on_delete: :cascade
    add_foreign_key :goals, :sellers, on_delete: :cascade
    add_foreign_key :login_logs, :users, on_delete: :cascade
    add_foreign_key :order_items, :orders, on_delete: :cascade
    add_foreign_key :order_items, :products, on_delete: :cascade
    add_foreign_key :orders, :sellers, on_delete: :cascade
    add_foreign_key :products, :categories, on_delete: :cascade
    add_foreign_key :sales, :sellers, on_delete: :cascade
    add_foreign_key :schedules, :sellers, on_delete: :cascade
    add_foreign_key :schedules, :shifts, on_delete: :cascade
    add_foreign_key :schedules, :stores, on_delete: :cascade
    add_foreign_key :sellers, :stores, on_delete: :cascade
    add_foreign_key :sellers, :users, on_delete: :cascade
    add_foreign_key :shifts, :stores, on_delete: :cascade
  end
end
