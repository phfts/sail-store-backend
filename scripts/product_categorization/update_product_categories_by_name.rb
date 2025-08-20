#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'csv'

# Configurações
API_BASE_URL = 'https://sail-store-backend-3018fcb425c5.herokuapp.com'
TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo2NywiZW1haWwiOiJzdXBlcmFkbWluQGFwaS5jb20iLCJhZG1pbiI6dHJ1ZSwiZXhwIjoxNzg3MjMxNzYzfQ.SW0Snkizy89b3qhOmkQwW_BsFoD01Hafhiaiuxso6Jo'

# Mapeamento de categorias baseado no nome do produto
CATEGORY_MAPPING = {
  # Vestuário
  'BLUSA' => 114,
  'VESTIDO' => 115,
  'CALCA' => 116,
  'SAIA' => 117,
  'CAMISA' => 118,
  'JAQUETA' => 119,
  'REGATA' => 120,
  'BLAZER' => 121,
  'MACACAO' => 122,
  'SHORTS' => 123,
  
  # Acessórios
  'COLAR' => 105, # Bijuterias
  'BRINCO' => 105, # Bijuterias
  'PULSEIRA' => 105, # Bijuterias
  'ANEL' => 105, # Bijuterias
  'BOLSA' => 106, # Bolsas e Carteiras
  'CARTEIRA' => 106, # Bolsas e Carteiras
  'LENCO' => 112, # Lenços e Chapéus
  'CHAPEU' => 112, # Lenços e Chapéus
  'CINTO' => 101, # Vestuário
  
  # Casa e Decoração
  'DECORATIVO' => 110, # Decoração
  'VASO' => 110, # Decoração
  'BANDEJA' => 111, # Mesa e Cozinha
  'PRATO' => 111, # Mesa e Cozinha
  'COPO' => 111, # Mesa e Cozinha
  'TRAVESSA' => 111, # Mesa e Cozinha
  'LUMINARIA' => 110, # Decoração
  
  # Outros
  'TIARA' => 101, # Vestuário
  'PASHMINA' => 101, # Vestuário
  'CLUTCH' => 106, # Bolsas e Carteiras
  'CHAVEIRO' => 69, # Outros
  'POTE' => 111, # Mesa e Cozinha
  'CESTA' => 110, # Decoração
  'KIT' => 69, # Outros
  'ARGOLA' => 105, # Bijuterias
  'BRACELETE' => 105, # Bijuterias
  'PRESILHA' => 105, # Bijuterias
  'TESOURA' => 110, # Decoração
  'ABRIDOR' => 110, # Decoração
  'CAIXA' => 110, # Decoração
  'LUPA' => 110, # Decoração
  'CAPA' => 110, # Decoração
  'SABONETE' => 110, # Decoração
  'DIFUSOR' => 110, # Decoração
  'SABONETE LIQUIDO' => 110, # Decoração
  'FITA METRICA' => 110, # Decoração
  'TALHERES' => 111, # Mesa e Cozinha
  'BULE' => 111, # Mesa e Cozinha
  'JOGO AMERICANO' => 111, # Mesa e Cozinha
  'PORTA SAL' => 111, # Mesa e Cozinha
  'PIMENTA' => 111, # Mesa e Cozinha
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
    
    if external_id && name
      product_names[external_id] = name
    end
  end
  
  product_names
end

def get_category_from_name(name)
  return nil unless name
  
  # Converter para maiúsculas para comparação
  name_upper = name.upcase
  
  # Procurar por palavras-chave no nome
  CATEGORY_MAPPING.each do |keyword, category_id|
    if name_upper.include?(keyword)
      return category_id
    end
  end
  
  nil
end

puts "🚀 Iniciando categorização por nome dos produtos..."
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
categorized_count = 0
errors = []
category_stats = {}

sold_products.each do |product|
  external_id = product['external_id']
  product_name = product_names[external_id]
  
  if product_name
    category_id = get_category_from_name(product_name)
    
    if category_id
      # Atualizar categoria
      update_data = { product: { category_id: category_id } }
      
      begin
        result = make_request(:put, "/products/#{product['id']}", update_data)
        
        if result['id']
          categorized_count += 1
          category_stats[category_id] ||= 0
          category_stats[category_id] += 1
          puts "✅ Produto #{product['id']} (#{external_id}) → #{product_name} → Categoria #{category_id}"
        else
          errors << "Erro ao atualizar produto #{product['id']}: #{result}"
        end
      rescue => e
        errors << "Exceção ao atualizar produto #{product['id']}: #{e.message}"
      end
    else
      puts "⚠️  Produto #{product['id']} (#{external_id}) → #{product_name} → Sem categoria encontrada"
    end
  else
    puts "⚠️  Produto #{product['id']} (#{external_id}) → Não encontrado no CSV"
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

puts "\n🎉 Categorização por nome concluída!"
