#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'csv'

# Configurações para desenvolvimento
API_BASE_URL = 'http://localhost:3000'
TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoyLCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODcyMzg3NDR9.g_37Fry1jB2xIlz3gC3nXm_zV6e1FK0tdbRTskvNo5Y'

# Mapeamento de categorias baseado no nome do produto (IDs do desenvolvimento)
CATEGORY_MAPPING = {
  # Vestuário
  'BLUSA' => 8,
  'VESTIDO' => 9,
  'CALCA' => 10,
  'SAIA' => 11,
  'CAMISA' => 12,
  'JAQUETA' => 13,
  'REGATA' => 14,
  'BLAZER' => 15,
  'MACACAO' => 16,
  'SHORTS' => 17,
  
  # Acessórios
  'COLAR' => 2, # Bijuterias
  'BRINCO' => 2, # Bijuterias
  'PULSEIRA' => 2, # Bijuterias
  'ANEL' => 2, # Bijuterias
  'BOLSA' => 3, # Bolsas e Carteiras
  'CARTEIRA' => 3, # Bolsas e Carteiras
  'LENCO' => 4, # Lenços e Chapéus
  'CHAPEU' => 4, # Lenços e Chapéus
  'CINTO' => 1, # Vestuário
  
  # Casa e Decoração
  'DECORATIVO' => 5, # Decoração
  'VASO' => 5, # Decoração
  'BANDEJA' => 6, # Mesa e Cozinha
  'PRATO' => 6, # Mesa e Cozinha
  'COPO' => 6, # Mesa e Cozinha
  'TRAVESSA' => 6, # Mesa e Cozinha
  'LUMINARIA' => 5, # Decoração
  
  # Outros
  'TIARA' => 1, # Vestuário
  'PASHMINA' => 1, # Vestuário
  'CLUTCH' => 3, # Bolsas e Carteiras
  'CHAVEIRO' => 7, # Outros
  'POTE' => 6, # Mesa e Cozinha
  'CESTA' => 5, # Decoração
  'KIT' => 7, # Outros
  'ARGOLA' => 2, # Bijuterias
  'BRACELETE' => 2, # Bijuterias
  'PRESILHA' => 2, # Bijuterias
  'TESOURA' => 5, # Decoração
  'ABRIDOR' => 5, # Decoração
  'CAIXA' => 5, # Decoração
  'LUPA' => 5, # Decoração
  'CAPA' => 5, # Decoração
  'SABONETE' => 5, # Decoração
  'DIFUSOR' => 5, # Decoração
  'SABONETE LIQUIDO' => 5, # Decoração
  'FITA METRICA' => 5, # Decoração
  'TALHERES' => 6, # Mesa e Cozinha
  'BULE' => 6, # Mesa e Cozinha
  'JOGO AMERICANO' => 6, # Mesa e Cozinha
  'PORTA SAL' => 6, # Mesa e Cozinha
  'PIMENTA' => 6, # Mesa e Cozinha
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
  http.use_ssl = false # Desenvolvimento usa HTTP
  
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

puts "🚀 Iniciando atualização de produtos no ambiente de desenvolvimento..."
puts "=" * 60

# Carregar nomes dos produtos do CSV
puts "📋 Carregando nomes dos produtos do CSV..."
product_names = load_product_names_from_csv
puts "✅ Carregados #{product_names.length} produtos do CSV"

# Buscar todos os produtos
puts "📋 Buscando produtos..."
products = make_request(:get, '/products?per_page=1000')
puts "✅ Encontrados #{products.length} produtos"

# Contadores
updated_names = 0
categorized_count = 0
errors = []
category_stats = {}

products.each do |product|
  external_id = product['external_id']
  product_name = product_names[external_id]
  
  if product_name
    # Atualizar nome do produto
    update_data = { product: { name: product_name } }
    
    begin
      result = make_request(:put, "/products/#{product['id']}", update_data)
      
      if result['id']
        updated_names += 1
        puts "✅ Nome atualizado: Produto #{product['id']} (#{external_id}) → #{product_name}"
        
        # Categorizar produto
        category_id = get_category_from_name(product_name)
        
        if category_id
          # Atualizar categoria
          category_update_data = { product: { category_id: category_id } }
          
          begin
            category_result = make_request(:put, "/products/#{product['id']}", category_update_data)
            
            if category_result['id']
              categorized_count += 1
              category_stats[category_id] ||= 0
              category_stats[category_id] += 1
              puts "  📂 Categoria: #{product_name} → Categoria #{category_id}"
            else
              errors << "Erro ao categorizar produto #{product['id']}: #{category_result}"
            end
          rescue => e
            errors << "Exceção ao categorizar produto #{product['id']}: #{e.message}"
          end
        else
          # Se não encontrou categoria específica, verificar se é "Produto XXX"
          if product_name.upcase.start_with?('PRODUTO ')
            # Categorizar como "Outros"
            category_update_data = { product: { category_id: 7 } } # Outros
            
            begin
              category_result = make_request(:put, "/products/#{product['id']}", category_update_data)
              
              if category_result['id']
                categorized_count += 1
                category_stats[7] ||= 0
                category_stats[7] += 1
                puts "  📂 Categoria: #{product_name} → Outros (7)"
              else
                errors << "Erro ao categorizar produto #{product['id']} como Outros: #{category_result}"
              end
            rescue => e
              errors << "Exceção ao categorizar produto #{product['id']} como Outros: #{e.message}"
            end
          else
            puts "  ⚠️  Sem categoria encontrada para: #{product_name}"
          end
        end
      else
        errors << "Erro ao atualizar nome do produto #{product['id']}: #{result}"
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
puts "✅ Nomes atualizados: #{updated_names}"
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

puts "\n🎉 Atualização no ambiente de desenvolvimento concluída!"
