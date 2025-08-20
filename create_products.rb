#!/usr/bin/env ruby
puts '🏭 Criando produtos necessários em produção...'

iguatemi_store = Store.find_by(slug: 'souq-sp-iguatemi-sp')
company = iguatemi_store.company
category = company.categories.first

backup_dir = Rails.root.join('db', 'souq_data')
orders_data = JSON.parse(File.read(backup_dir.join('06_orders.json')))

# Coletar todos os external_ids únicos
product_external_ids = Set.new
orders_data.each do |order_data|
  if order_data['order_items']
    order_data['order_items'].each do |item_data|
      product_external_ids.add(item_data['product_external_id'])
    end
  end
end

puts "📦 Total de produtos a criar: #{product_external_ids.count}"

created_count = 0
existing_count = 0

product_external_ids.each_with_index do |external_id, index|
  if index % 100 == 0
    puts "  🔨 Criando produto #{index + 1} de #{product_external_ids.count}"
  end
  
  # Verificar se já existe
  unless Product.exists?(external_id: external_id)
    Product.create!(
      name: "Produto #{external_id}",
      category_id: category.id,
      external_id: external_id,
      price: 50.0
    )
    created_count += 1
  else
    existing_count += 1
  end
end

puts '✅ Criação de produtos concluída:'
puts "  ✅ Produtos criados: #{created_count}"
puts "  ℹ️ Produtos já existiam: #{existing_count}"
puts "🎯 Total de produtos na categoria: #{category.products.count}"

