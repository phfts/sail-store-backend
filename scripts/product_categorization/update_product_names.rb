#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'csv'

# Configurações
API_BASE_URL = 'https://sail-store-backend-3018fcb425c5.herokuapp.com'
TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo2NywiZW1haWwiOiJzdXBlcmFkbWluQGFwaS5jb20iLCJhZG1pbiI6dHJ1ZSwiZXhwIjoxNzg3MjMxNzYzfQ.SW0Snkizy89b3qhOmkQwW_BsFoD01Hafhiaiuxso6Jo'

# Mapeamento de prefixos para categorias
CATEGORY_MAPPING = {
  '01' => 100, # Eletrônicos
  '02' => 101, # Vestuário
  '04' => 102, # Casa e Decoração
  '05' => 103  # Esportes e Lazer
}

def make_request(method, endpoint, data = nil)
  uri = URI("#{API_BASE_URL}#{endpoint}")
  
  case method
  when :get
    request = Net::HTTP::Get.new(uri)
  when :put
    request = Net::HTTP::Put.new(uri)
    request.body = data.to_json if data
  end
  
  request['Authorization'] = "Bearer #{TOKEN}"
  request['Content-Type'] = 'application/json'
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  response = http.request(request)
  JSON.parse(response.body)
end

def load_product_names_from_csv
  product_names = {}
  
  # Carregar dados de um arquivo CSV
  csv_file = "/home/paulo/Downloads/souq-data/souq-data/products/LinxProdutos_store=52396451000193_beginDate=2025-01-01_endDate=2025-08-12.csv"
  
  CSV.foreach(csv_file, headers: true) do |row|
    external_id = row['cod_produto']
    name = row['nome']
    sku = row['cod_barra']
    
    if external_id && name
      product_names[external_id] = {
        name: name,
        sku: sku
      }
    end
  end
  
  product_names
end

puts "🚀 Iniciando atualização de nomes e categorias dos produtos..."
puts "=" * 60

# Carregar nomes dos produtos do CSV
puts "📋 Carregando nomes dos produtos do CSV..."
product_names = load_product_names_from_csv
puts "✅ Carregados #{product_names.length} produtos do CSV"

# Buscar produtos vendidos
puts "📋 Buscando produtos vendidos..."
orders = make_request(:get, '/orders?per_page=100')
sold_products = []

orders.each do |order|
  order['order_items'].each do |item|
    product = item['product']
    if product && !sold_products.any? { |p| p['external_id'] == product['external_id'] }
      sold_products << product
    end
  end
end

puts "✅ Encontrados #{sold_products.length} produtos vendidos únicos"

# Contadores
updated_count = 0
errors = []

sold_products.each do |product|
  external_id = product['external_id']
  csv_data = product_names[external_id]
  
  if csv_data
    # Atualizar nome e categoria
    update_data = { product: { name: csv_data[:name] } }
    
    # Categorizar baseado no SKU se disponível
    if csv_data[:sku] && csv_data[:sku].length >= 2
      prefix = csv_data[:sku][0..1]
      if CATEGORY_MAPPING[prefix]
        update_data[:product][:category_id] = CATEGORY_MAPPING[prefix]
      end
    end
    
    begin
      result = make_request(:put, "/products/#{product['id']}", update_data)
      
      if result['id']
        updated_count += 1
        category_info = update_data[:product][:category_id] ? " → Categoria #{update_data[:product][:category_id]}" : ""
        puts "✅ Produto #{product['id']} (#{external_id}) → #{csv_data[:name]}#{category_info}"
      else
        errors << "Erro ao atualizar produto #{product['id']}: #{result}"
      end
    rescue => e
      errors << "Exceção ao atualizar produto #{product['id']}: #{e.message}"
    end
  else
    puts "⚠️  Produto #{product['id']} (#{external_id}) → Não encontrado no CSV"
  end
end

puts "=" * 60
puts "📊 Resumo da atualização:"
puts "✅ Produtos atualizados: #{updated_count}"
puts "❌ Erros: #{errors.length}"

if errors.any?
  puts "\n❌ Erros encontrados:"
  errors.each { |error| puts "  - #{error}" }
end

puts "\n🎉 Atualização concluída!"
