#!/usr/bin/env ruby

# Script para verificar vendas de um vendedor específico em uma data específica
# Uso: heroku run rails runner scripts/check_seller_sales.rb

require_relative '../config/environment'

# Configurações
seller_name = "JOYCE DE L PEREIRA"
target_date = Date.parse("2025-08-01")

puts "=" * 60
puts "CONSULTA DE VENDAS POR VENDEDOR E DATA"
puts "=" * 60
puts "Vendedor: #{seller_name}"
puts "Data: #{target_date.strftime('%d/%m/%Y')}"
puts "=" * 60

# Buscar o vendedor
seller = Seller.find_by(name: seller_name)

if seller.nil?
  puts "❌ Vendedor '#{seller_name}' não encontrado!"
  puts "\nVendedores disponíveis:"
  Seller.all.order(:name).each do |s|
    puts "  - #{s.name}"
  end
  exit 1
end

puts "✅ Vendedor encontrado: #{seller.name} (ID: #{seller.id})"

# Buscar pedidos do vendedor na data específica
orders = seller.orders.where(sold_at: target_date)

if orders.empty?
  puts "\n📊 RESULTADO:"
  puts "❌ Nenhuma venda encontrada para #{seller.name} em #{target_date.strftime('%d/%m/%Y')}"
  exit 0
end

puts "\n📊 RESULTADO:"
puts "Encontrados #{orders.count} pedido(s) para #{seller.name} em #{target_date.strftime('%d/%m/%Y')}"

total_sales = 0
total_items = 0

orders.each_with_index do |order, index|
  puts "\n--- Pedido ##{index + 1} ---"
  puts "ID do Pedido: #{order.id}"
  puts "Data: #{order.sold_at.strftime('%d/%m/%Y')}"
  puts "Status: #{order.status}"
  
  # Calcular vendas do pedido
  order_items = order.order_items.includes(:product)
  order_total = 0
  
  if order_items.any?
    puts "\nItens do pedido:"
    order_items.each do |item|
      item_total = item.quantity * item.unit_price
      order_total += item_total
      puts "  - #{item.product.name}: #{item.quantity}x R$ #{item.unit_price} = R$ #{item_total}"
    end
  else
    puts "  (Nenhum item encontrado)"
  end
  
  puts "Total do pedido: R$ #{order_total}"
  total_sales += order_total
  total_items += order_items.sum(:quantity)
end

puts "\n" + "=" * 60
puts "RESUMO FINAL:"
puts "=" * 60
puts "Vendedor: #{seller.name}"
puts "Data: #{target_date.strftime('%d/%m/%Y')}"
puts "Total de pedidos: #{orders.count}"
puts "Total de itens vendidos: #{total_items}"
puts "Total de vendas: R$ #{total_sales}"
puts "=" * 60
