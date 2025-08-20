#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'csv'

# Configurações
API_BASE_URL = 'https://sail-store-backend-3018fcb425c5.herokuapp.com'
TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo2NywiZW1haWwiOiJzdXBlcmFkbWluQGFwaS5jb20iLCJhZG1pbiI6dHJ1ZSwiZXhwIjoxNzg3MjMxNzYzfQ.SW0Snkizy89b3qhOmkQwW_BsFoD01Hafhiaiuxso6Jo'

# Mapeamento de categorias específicas baseado nos dados das planilhas
CATEGORY_MAPPING = {
  # Jeans
  'ROUPA,JEANS' => 104,
  'ROUPA IDA,JEANS IDA' => 104,
  
  # Bijuterias
  'ACESSORIO,BIJOUX' => 105,
  
  # Bolsas e Carteiras
  'ACESSORIO,BOLSA' => 106,
  'ACESSORIO,CARTEIRA E ORGANIZADOR' => 106,
  
  # Malha
  'ROUPA,MALHA' => 107,
  'ROUPA IDA,MALHA IDA' => 107,
  
  # Tecido Plano
  'ROUPA,TECIDO PLANO' => 108,
  'ROUPA IDA,TECIDO PLANO IDA' => 108,
  
  # Tricot
  'ROUPA,TRICOT' => 109,
  'ROUPA IDA,TRICOT IDA' => 109,
  
  # Decoração
  'HOME,DECORACAO' => 110,
  
  # Mesa e Cozinha
  'HOME,MESA' => 111,
  
  # Lenços e Chapéus
  'ACESSORIO,LENCO' => 112,
  'ACESSORIO,CHAPEU' => 112,
  
  # Praia
  'PRAIA IDA,MALHA IDA (PRAIA)' => 113,
  
  # Outros acessórios
  'ACESSORIO,SAPATO E CINTO' => 101, # Vestuário
  'ACESSORIO,NECESSAIRE' => 101, # Vestuário
  'ACESSORIO,OUTRO ACESSORIO' => 101, # Vestuário
  'ACESSORIO,PELERINE A' => 101, # Vestuário
  'ACESSORIO,GOLA' => 101, # Vestuário
  
  # Outros HOME
  'HOME,PAPELARIA' => 102, # Casa e Decoração
  'HOME,MOBILIARIO' => 102, # Casa e Decoração
  'HOME,COMPLEMENTAR' => 102, # Casa e Decoração
  
  # Outros
  'SERVICO,MAO DE OBRA PA' => 69, # Outros
  'MATERIAL,TECIDO' => 69, # Outros
  'MATERIAL,INSUMO AVIAMENTO' => 69, # Outros
  'MATERIAL,INSUMO CD' => 69, # Outros
  'MATERIAL,INSUMO LOJA' => 69, # Outros
  'MATERIAL IDA,TECIDO IDA' => 69, # Outros
  'BRINDE IDA,BRINDE IDA' => 69, # Outros
  'ACESSORIO IDA,ACESSORIO IDA' => 69, # Outros
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

def load_product_categories_from_csv
  product_categories = {}
  
  # Carregar dados de um arquivo CSV
  csv_file = "/home/paulo/Downloads/souq-data/souq-data/products/LinxProdutos_store=52396451000193_beginDate=2025-01-01_endDate=2025-08-12.csv"
  
  CSV.foreach(csv_file, headers: true) do |row|
    external_id = row['cod_produto']
    setor = row['desc_setor']
    linha = row['desc_linha']
    
    if external_id && setor && linha
      category_key = "#{setor},#{linha}"
      product_categories[external_id] = category_key
    end
  end
  
  product_categories
end

puts "🚀 Iniciando categorização específica dos produtos..."
puts "=" * 60

# Carregar categorias dos produtos do CSV
puts "📋 Carregando categorias dos produtos do CSV..."
product_categories = load_product_categories_from_csv
puts "✅ Carregados #{product_categories.length} produtos do CSV"

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
categorized_count = 0
errors = []
category_stats = {}

sold_products.each do |product|
  external_id = product['external_id']
  csv_category = product_categories[external_id]
  
  if csv_category && CATEGORY_MAPPING[csv_category]
    category_id = CATEGORY_MAPPING[csv_category]
    
    # Atualizar categoria
    update_data = { product: { category_id: category_id } }
    
    begin
      result = make_request(:put, "/products/#{product['id']}", update_data)
      
      if result['id']
        categorized_count += 1
        category_stats[category_id] ||= 0
        category_stats[category_id] += 1
        puts "✅ Produto #{product['id']} (#{external_id}) → #{csv_category} → Categoria #{category_id}"
      else
        errors << "Erro ao atualizar produto #{product['id']}: #{result}"
      end
    rescue => e
      errors << "Exceção ao atualizar produto #{product['id']}: #{e.message}"
    end
  else
    puts "⚠️  Produto #{product['id']} (#{external_id}) → #{csv_category || 'Não encontrado'} → Sem mapeamento"
  end
end

puts "=" * 60
puts "📊 Resumo da categorização:"
puts "✅ Produtos categorizados: #{categorized_count}"
puts "❌ Erros: #{errors.length}"

puts "\n📈 Estatísticas por categoria:"
category_stats.each do |category_id, count|
  puts "  - Categoria #{category_id}: #{count} produtos"
end

if errors.any?
  puts "\n❌ Erros encontrados:"
  errors.each { |error| puts "  - #{error}" }
end

puts "\n🎉 Categorização específica concluída!"
