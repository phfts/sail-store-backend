class CreateQueueItems < ActiveRecord::Migration[8.0]
  def change
    create_table :queue_items do |t|
      t.references :seller, null: true, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :status, default: 'waiting', null: false
      t.integer :priority, default: 1, null: false
      t.text :notes
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    
    add_index :queue_items, [:store_id, :status]
    add_index :queue_items, [:seller_id, :status]
    add_index :queue_items, :created_at
  end
end
