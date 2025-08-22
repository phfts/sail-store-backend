#!/usr/bin/env ruby

# Script para verificar quais vendedores têm vendas na loja Morumbi e em quais dias
# Uso: heroku run rails runner scripts/check_morumbi_sellers_sales.rb

require_relative '../config/environment'

puts "=" * 80
puts "CONSULTA DE VENDAS POR VENDEDORES NA LOJA MORUMBI"
puts "=" * 80

# Buscar a loja Morumbi
morumbi_store = Store.find_by("LOWER(name) LIKE ?", "%morumbi%")

if morumbi_store.nil?
  puts "❌ Loja 'Morumbi' não encontrada!"
  puts "\nLojas disponíveis:"
  Store.all.order(:name).each do |store|
    puts "  - #{store.name} (ID: #{store.id})"
  end
  exit 1
end

puts "✅ Loja encontrada: #{morumbi_store.name} (ID: #{morumbi_store.id})"
puts "Empresa: #{morumbi_store.company.name}"
puts "=" * 80

# Buscar todos os vendedores da loja Morumbi
sellers = morumbi_store.sellers.order(:name)

if sellers.empty?
  puts "❌ Nenhum vendedor encontrado na loja #{morumbi_store.name}"
  exit 1
end

puts "📋 Vendedores encontrados na loja #{morumbi_store.name}: #{sellers.count}"
sellers.each_with_index do |seller, index|
  puts "  #{index + 1}. #{seller.name} (ID: #{seller.id})"
end

puts "\n" + "=" * 80
puts "ANÁLISE DE VENDAS POR VENDEDOR"
puts "=" * 80

# Para cada vendedor, verificar suas vendas
sellers_with_sales = []
sellers_without_sales = []

sellers.each do |seller|
  puts "\n🔍 Analisando vendedor: #{seller.name}"
  
  # Buscar todas as vendas do vendedor
  orders = seller.orders.order(:sold_at)
  
  if orders.empty?
    puts "  ❌ Nenhuma venda encontrada"
    sellers_without_sales << seller
    next
  end
  
  puts "  ✅ Encontradas #{orders.count} vendas"
  
  # Agrupar vendas por data
  sales_by_date = orders.group_by { |order| order.sold_at.to_date }
  
  puts "  📅 Vendas por dia:"
  total_sales_value = 0
  
  sales_by_date.each do |date, day_orders|
    day_total = day_orders.sum(&:total)
    total_sales_value += day_total
    puts "    #{date.strftime('%d/%m/%Y')}: #{day_orders.count} pedido(s) - R$ #{day_total}"
  end
  
  puts "  💰 Total de vendas: R$ #{total_sales_value}"
  
  sellers_with_sales << {
    seller: seller,
    total_orders: orders.count,
    total_value: total_sales_value,
    sales_dates: sales_by_date.keys.sort,
    sales_by_date: sales_by_date
  }
end

puts "\n" + "=" * 80
puts "RESUMO FINAL"
puts "=" * 80

puts "📊 Vendedores COM vendas: #{sellers_with_sales.count}"
if sellers_with_sales.any?
  puts "\nVendedores que já venderam:"
  sellers_with_sales.each_with_index do |data, index|
    seller = data[:seller]
    puts "  #{index + 1}. #{seller.name}"
    puts "     - Total de pedidos: #{data[:total_orders]}"
    puts "     - Total de vendas: R$ #{data[:total_value]}"
    puts "     - Dias com vendas: #{data[:sales_dates].count}"
    puts "     - Primeira venda: #{data[:sales_dates].first.strftime('%d/%m/%Y')}"
    puts "     - Última venda: #{data[:sales_dates].last.strftime('%d/%m/%Y')}"
    puts "     - Dias específicos: #{data[:sales_dates].map { |d| d.strftime('%d/%m/%Y') }.join(', ')}"
    puts ""
  end
end

puts "📊 Vendedores SEM vendas: #{sellers_without_sales.count}"
if sellers_without_sales.any?
  puts "\nVendedores que ainda não venderam:"
  sellers_without_sales.each_with_index do |seller, index|
    puts "  #{index + 1}. #{seller.name}"
  end
end

# Estatísticas gerais
total_sellers = sellers.count
total_sellers_with_sales = sellers_with_sales.count
total_sellers_without_sales = sellers_without_sales.count
total_orders = sellers_with_sales.sum { |data| data[:total_orders] }
total_value = sellers_with_sales.sum { |data| data[:total_value] }

puts "\n" + "=" * 80
puts "ESTATÍSTICAS GERAIS"
puts "=" * 80
puts "Total de vendedores na loja: #{total_sellers}"
puts "Vendedores com vendas: #{total_sellers_with_sales} (#{(total_sellers_with_sales.to_f / total_sellers * 100).round(1)}%)"
puts "Vendedores sem vendas: #{total_sellers_without_sales} (#{(total_sellers_without_sales.to_f / total_sellers * 100).round(1)}%)"
puts "Total de pedidos: #{total_orders}"
puts "Total de vendas: R$ #{total_value}"

# Verificar todos os dias únicos com vendas
all_sales_dates = sellers_with_sales.flat_map { |data| data[:sales_dates] }.uniq.sort

if all_sales_dates.any?
  puts "\n📅 Todos os dias com vendas na loja:"
  all_sales_dates.each do |date|
    sellers_on_date = sellers_with_sales.select { |data| data[:sales_dates].include?(date) }
    puts "  #{date.strftime('%d/%m/%Y')}: #{sellers_on_date.count} vendedor(es) ativo(s)"
  end
end

puts "=" * 80
