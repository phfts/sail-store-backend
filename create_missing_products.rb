#!/usr/bin/env ruby
puts '🏭 Criando produtos necessários para corrigir os external_ids...'

backup_dir = Rails.root.join('db', 'souq_data')
orders_data = JSON.parse(File.read(backup_dir.join('06_orders.json')))

# Buscar empresa e categoria
company = Company.find_by(name: 'SOUQ')
category = company.categories.first

puts "🏢 Empresa: #{company.name}"
puts "📂 Categoria: #{category.name}"

# Coletar todos os external_ids únicos necessários
needed_product_ids = Set.new
orders_data.each do |order_data|
  if order_data['order_items']
    order_data['order_items'].each do |item_data|
      needed_product_ids.add(item_data['product_external_id'])
    end
  end
end

puts "📦 Produtos únicos necessários: #{needed_product_ids.count}"

created_count = 0
existing_count = 0

needed_product_ids.each_with_index do |external_id, index|
  if index % 100 == 0
    puts "  🔨 Processando produto #{index + 1} de #{needed_product_ids.count}"
  end
  
  # Verificar se já existe
  unless Product.exists?(external_id: external_id)
    Product.create!(
      name: "Produto #{external_id}",
      category_id: category.id,
      external_id: external_id
    )
    created_count += 1
  else
    existing_count += 1
  end
end

puts "✅ Produtos criados: #{created_count}"
puts "ℹ️ Produtos já existentes: #{existing_count}"
puts "📊 Total de produtos agora: #{Product.count}"
