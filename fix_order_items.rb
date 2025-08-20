#!/usr/bin/env ruby
puts '🔧 Criando order_items para vendas da loja Iguatemi...'

iguatemi_store = Store.find_by(slug: 'souq-sp-iguatemi-sp')
puts "🏪 Loja: #{iguatemi_store.name}"

# Buscar dados do backup
backup_dir = Rails.root.join('db', 'souq_data')
file_path = backup_dir.join('06_orders.json')

if File.exist?(file_path)
  orders_data = JSON.parse(File.read(file_path))
  puts "📊 Total de vendas no backup: #{orders_data.count}"
  
  created_items = 0
  skipped_items = 0
  processed_orders = 0
  
  orders_data.each_with_index do |order_data, index|
    if index % 500 == 0
      puts "  📦 Processando venda #{index + 1} de #{orders_data.count}"
    end
    
    # Buscar a venda pelo external_id
    order = Order.find_by(external_id: order_data['external_id'])
    next unless order
    
    processed_orders += 1
    
    # Criar os itens se não existirem
    if order.order_items.count == 0 && order_data['order_items']
      order_data['order_items'].each do |item_data|
        # Buscar produto pelo external_id
        product = Product.find_by(external_id: item_data['product_external_id'])
        
        if product
          OrderItem.create!(
            order: order,
            product: product,
            store_id: iguatemi_store.id,
            quantity: item_data['quantity'] || 1,
            unit_price: item_data['unit_price'] || 0,
            external_id: item_data['external_id']
          )
          created_items += 1
        else
          skipped_items += 1
        end
      end
    end
  end
  
  puts '✅ Processamento concluído:'
  puts "  📦 Vendas processadas: #{processed_orders}"
  puts "  ✅ Itens criados: #{created_items}"
  puts "  ❌ Itens ignorados: #{skipped_items}"
  
  # Verificar resultado final
  final_items = OrderItem.joins(order: :seller).where(sellers: { store_id: iguatemi_store.id }).count
  puts "🎯 Total final de itens: #{final_items}"
else
  puts '❌ Arquivo de backup não encontrado'
end

