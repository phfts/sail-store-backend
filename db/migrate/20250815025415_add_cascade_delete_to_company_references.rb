class AddCascadeDeleteToCompanyReferences < ActiveRecord::Migration[8.0]
  def change
    # Remove existing foreign keys and add them back with cascade delete
    
    remove_foreign_key :adjustments, :companies if foreign_key_exists?(:adjustments, :companies)
    add_foreign_key :adjustments, :companies, on_delete: :cascade
    
    remove_foreign_key :categories, :companies if foreign_key_exists?(:categories, :companies)
    add_foreign_key :categories, :companies, on_delete: :cascade
    
    remove_foreign_key :queue_items, :companies if foreign_key_exists?(:queue_items, :companies)
    add_foreign_key :queue_items, :companies, on_delete: :cascade
    
    remove_foreign_key :sellers, :companies if foreign_key_exists?(:sellers, :companies)
    add_foreign_key :sellers, :companies, on_delete: :cascade
    
    remove_foreign_key :stores, :companies if foreign_key_exists?(:stores, :companies)
    add_foreign_key :stores, :companies, on_delete: :cascade
  end
end
