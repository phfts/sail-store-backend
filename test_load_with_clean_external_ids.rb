#!/usr/bin/env ruby
puts '🏭 Carregando dados no ambiente TEST com external_ids limpos...'

backup_dir = Rails.root.join('db', 'souq_data')

# 1. Restaurar estrutura básica (empresa, loja, categoria)
puts '📋 1. Criando estrutura básica...'
company_data = JSON.parse(File.read(backup_dir.join('01_company.json')))
company = Company.create!(
  name: company_data['name'],
  slug: company_data['slug'],
  description: company_data['description']
)

store_data = JSON.parse(File.read(backup_dir.join('02_store.json')))
store = Store.create!(
  name: store_data['name'],
  cnpj: store_data['cnpj'],
  external_id: store_data['external_id'],
  company_id: company.id,
  slug: store_data['slug']
)

category_data = JSON.parse(File.read(backup_dir.join('03_category.json')))
category = Category.create!(
  name: category_data['name'],
  company_id: company.id,
  external_id: category_data['external_id']
)

puts "✅ Estrutura criada: #{company.name} > #{store.name} > #{category.name}"

# 2. Criar produtos com external_ids LIMPOS
puts '📦 2. Criando produtos com external_ids limpos...'
products_data = JSON.parse(File.read(backup_dir.join('05_products.json')))

products_data.each_with_index do |product_data, index|
  if index % 100 == 0
    puts "   🔨 Produto #{index + 1} de #{products_data.count}"
  end
  
  # LIMPAR external_id: remover prefixos e sufixos
  clean_external_id = product_data['external_id'].to_s.gsub(/[^0-9]/, '')
  
  Product.create!(
    name: product_data['name'],
    category_id: category.id,
    external_id: clean_external_id
  )
end

puts "✅ #{products_data.count} produtos criados com external_ids limpos"

# 3. Criar vendedores
puts '👥 3. Criando vendedores...'
sellers_data = JSON.parse(File.read(backup_dir.join('04_sellers.json')))

sellers_data.each do |seller_data|
  Seller.create!(
    name: seller_data['name'],
    external_id: seller_data['external_id'],
    company_id: company.id,
    store_id: store.id,
    whatsapp: seller_data['whatsapp'],
    active_until: seller_data['active_until'],
    is_busy: seller_data['is_busy']
  )
end

puts "✅ #{sellers_data.count} vendedores criados"

# 4. Criar vendas e itens com external_ids LIMPOS
puts '🛒 4. Criando vendas e itens...'
orders_data = JSON.parse(File.read(backup_dir.join('06_orders.json')))

created_orders = 0
created_items = 0
skipped_items = 0

orders_data.each_with_index do |order_data, index|
  if index % 500 == 0
    puts "   📦 Venda #{index + 1} de #{orders_data.count}"
  end
  
  # Buscar vendedor
  seller = Seller.find_by(
    company_id: company.id,
    external_id: order_data['seller_external_id']
  )
  
  next unless seller
  
  # Criar venda
  order = Order.create!(
    external_id: order_data['external_id'],
    seller_id: seller.id,
    sold_at: order_data['sold_at']
  )
  created_orders += 1
  
  # Criar itens da venda
  if order_data['order_items']
    order_data['order_items'].each do |item_data|
      # LIMPAR product_external_id: remover prefixos e sufixos
      clean_product_external_id = item_data['product_external_id'].to_s.gsub(/[^0-9]/, '')
      
      product = Product.find_by(external_id: clean_product_external_id)
      
      if product
        OrderItem.create!(
          product_id: product.id,
          order_id: order.id,
          store_id: store.id,
          quantity: item_data['quantity'],
          unit_price: item_data['unit_price'],
          external_id: item_data['external_id']
        )
        created_items += 1
      else
        skipped_items += 1
      end
    end
  end
end

puts "✅ #{created_orders} vendas criadas"
puts "✅ #{created_items} itens criados"
puts "⚠️ #{skipped_items} itens ignorados (produto não encontrado)"

puts "\n📊 RESUMO FINAL:"
puts "🏢 Empresa: #{Company.count}"
puts "🏪 Lojas: #{Store.count}"
puts "📂 Categorias: #{Category.count}"
puts "📦 Produtos: #{Product.count}"
puts "👥 Vendedores: #{Seller.count}"
puts "🛒 Vendas: #{Order.count}"
puts "📋 Itens: #{OrderItem.count}"
