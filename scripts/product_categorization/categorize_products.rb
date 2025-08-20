#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

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

puts "🚀 Iniciando categorização automática de produtos..."
puts "=" * 50

# Buscar todos os produtos com SKU
puts "📋 Buscando produtos com SKU..."
products = make_request(:get, '/products?per_page=1000')

products_with_sku = products.select { |p| p['sku'] && !p['sku'].empty? }
puts "✅ Encontrados #{products_with_sku.length} produtos com SKU"

# Contadores
categorized_count = 0
errors = []

products_with_sku.each do |product|
  sku = product['sku']
  prefix = sku[0..1]
  
  if CATEGORY_MAPPING[prefix]
    category_id = CATEGORY_MAPPING[prefix]
    
    # Atualizar produto
    begin
      update_data = { product: { category_id: category_id } }
      result = make_request(:put, "/products/#{product['id']}", update_data)
      
      if result['id']
        categorized_count += 1
        puts "✅ Produto #{product['id']} (SKU: #{sku}) → Categoria #{category_id}"
      else
        errors << "Erro ao atualizar produto #{product['id']}: #{result}"
      end
    rescue => e
      errors << "Exceção ao atualizar produto #{product['id']}: #{e.message}"
    end
  else
    puts "⚠️  Produto #{product['id']} (SKU: #{sku}) → Prefixo #{prefix} não mapeado"
  end
end

puts "=" * 50
puts "📊 Resumo da categorização:"
puts "✅ Produtos categorizados: #{categorized_count}"
puts "❌ Erros: #{errors.length}"

if errors.any?
  puts "\n❌ Erros encontrados:"
  errors.each { |error| puts "  - #{error}" }
end

puts "\n🎉 Categorização concluída!"
