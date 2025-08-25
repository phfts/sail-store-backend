class MakeExternalIdUniqueForOrderItemsPerStore < ActiveRecord::Migration[8.0]
  def up
    # Primeiro, vamos identificar e remover os order_items com external_ids duplicados por store
    # Mantemos apenas o mais recente (maior ID) de cada grupo de duplicados
    
    # Encontrar todos os external_ids duplicados por store
    duplicate_groups = execute(<<-SQL)
      SELECT store_id, external_id, COUNT(*) as count
      FROM order_items 
      WHERE external_id IS NOT NULL 
      GROUP BY store_id, external_id 
      HAVING COUNT(*) > 1
    SQL
    
    duplicate_groups.each do |group|
      store_id = group['store_id']
      external_id = group['external_id']
      
      # Manter apenas o order_item com maior ID (mais recente) e remover os outros
      execute(<<-SQL)
        DELETE FROM order_items 
        WHERE store_id = #{store_id} 
        AND external_id = '#{external_id}' 
        AND id NOT IN (
          SELECT id FROM (
            SELECT id FROM order_items 
            WHERE store_id = #{store_id} 
            AND external_id = '#{external_id}' 
            ORDER BY id DESC 
            LIMIT 1
          ) AS keep_ids
        )
      SQL
    end
    
    # Criar índice único para store_id + external_id
    add_index :order_items, [:store_id, :external_id], unique: true, 
              name: 'index_order_items_on_store_id_and_external_id_unique',
              where: 'external_id IS NOT NULL'
  end

  def down
    # Remover o índice único
    remove_index :order_items, name: 'index_order_items_on_store_id_and_external_id_unique'
  end
end
