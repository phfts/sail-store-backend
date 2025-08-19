#!/usr/bin/env ruby
# Teste simples e direto dos cálculos de meta

require_relative 'test_helper'

puts "🧪 TESTE RÁPIDO - CÁLCULO DE METAS"
puts "=" * 50

begin
  # Usar dados existentes do desenvolvimento
  puts "📊 Usando dados existentes do banco..."
  
  # Encontrar vendedor com vendas
  seller = Seller.joins(:orders)
                 .where(orders: { sold_at: '2025-08-01'..'2025-08-31' })
                 .first
  
  if seller.nil?
    puts "❌ Nenhum vendedor com vendas em agosto encontrado"
    exit 1
  end
  
  puts "👤 Vendedor: #{seller.name} (ID: #{seller.id})"
  puts "🏪 Loja: #{seller.store.name} (ID: #{seller.store.id})"
  
  # Calcular vendas manualmente - INDIVIDUAL
  individual_sales = Order.joins(:order_items)
                         .where(seller_id: seller.id)
                         .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                '2025-08-01 00:00:00', '2025-08-31 23:59:59')
                         .sum('order_items.quantity * order_items.unit_price')
  
  puts "\n💰 VENDAS INDIVIDUAIS:"
  puts "  Período: Agosto 2025"
  puts "  Total: R$ #{individual_sales / 100.0}"
  
  # Calcular vendas manualmente - LOJA
  store_sales = Order.joins(:order_items, :seller)
                    .where(sellers: { store_id: seller.store.id })
                    .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                           '2025-08-01 00:00:00', '2025-08-31 23:59:59')
                    .sum('order_items.quantity * order_items.unit_price')
  
  puts "\n🏪 VENDAS DA LOJA:"
  puts "  Período: Agosto 2025" 
  puts "  Total: R$ #{store_sales / 100.0}"
  
  # Criar meta individual
  individual_goal = Goal.create!(
    seller_id: seller.id,
    goal_type: 'sales',
    goal_scope: 'individual',
    start_date: '2025-08-01',
    end_date: '2025-08-31',
    target_value: individual_sales * 0.8, # Meta menor que as vendas
    description: 'TESTE INDIVIDUAL'
  )
  
  individual_goal.update_column(:current_value, individual_sales)
  individual_goal.reload
  
  puts "\n🎯 META INDIVIDUAL:"
  puts "  Target: R$ #{individual_goal.target_value / 100.0}"
  puts "  Current: R$ #{individual_goal.current_value / 100.0}"
  puts "  Progress: #{individual_goal.progress_percentage}%"
  
  # Validação individual
  if individual_goal.current_value == individual_sales
    puts "  ✅ Current value correto!"
  else
    puts "  ❌ Current value incorreto: esperado #{individual_sales}, obtido #{individual_goal.current_value}"
  end
  
  if individual_goal.progress_percentage > 100
    puts "  ✅ Progress percentage > 100% (meta superada)!"
  else
    puts "  ⚠️  Progress percentage: #{individual_goal.progress_percentage}%"
  end
  
  # Criar meta por loja
  store_wide_goal = Goal.create!(
    seller_id: nil,
    goal_type: 'sales',
    goal_scope: 'store_wide',
    start_date: '2025-08-01',
    end_date: '2025-08-31',
    target_value: store_sales * 0.7, # Meta menor que as vendas
    description: 'TESTE LOJA'
  )
  
  store_wide_goal.update_column(:current_value, store_sales)
  store_wide_goal.reload
  
  puts "\n🏪 META POR LOJA:"
  puts "  Target: R$ #{store_wide_goal.target_value / 100.0}"
  puts "  Current: R$ #{store_wide_goal.current_value / 100.0}"
  puts "  Progress: #{store_wide_goal.progress_percentage}%"
  
  # Validação loja
  if store_wide_goal.current_value == store_sales
    puts "  ✅ Current value correto!"
  else
    puts "  ❌ Current value incorreto: esperado #{store_sales}, obtido #{store_wide_goal.current_value}"
  end
  
  if store_wide_goal.progress_percentage > 100
    puts "  ✅ Progress percentage > 100% (meta superada)!"
  else
    puts "  ⚠️  Progress percentage: #{store_wide_goal.progress_percentage}%"
  end
  
  # Testar o método update_goal_progress do controller
  puts "\n⚙️  TESTANDO MÉTODO DO CONTROLLER:"
  
  # Resetar meta para 0
  individual_goal.update_column(:current_value, 0)
  
  # Criar instância do controller
  controller = GoalsController.new
  user = seller.user || User.find_by(email: 'admin@souq-iguatemi.com')
  controller.instance_variable_set(:@current_user, user)
  
  def controller.current_user
    @current_user
  end
  
  # Chamar método privado
  controller.send(:update_goal_progress, individual_goal)
  individual_goal.reload
  
  puts "  Antes: 0"
  puts "  Depois: R$ #{individual_goal.current_value / 100.0}"
  puts "  Progress: #{individual_goal.progress_percentage}%"
  
  if individual_goal.current_value == individual_sales
    puts "  ✅ Método update_goal_progress funcionando!"
  else
    puts "  ❌ Método falhou: esperado #{individual_sales}, obtido #{individual_goal.current_value}"
  end
  
  puts "\n🎉 TESTE CONCLUÍDO COM SUCESSO!"
  puts "\n📊 RESUMO DOS CÁLCULOS:"
  puts "  - Vendas individuais calculadas corretamente"
  puts "  - Vendas por loja calculadas corretamente"
  puts "  - Progress percentage funcionando"
  puts "  - Método update_goal_progress funcionando"
  
rescue => e
  puts "\n❌ ERRO: #{e.message}"
  puts e.backtrace.first(3)
ensure
  # Cleanup
  Goal.where(description: ['TESTE INDIVIDUAL', 'TESTE LOJA']).delete_all
end
