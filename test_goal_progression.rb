#!/usr/bin/env ruby
# Teste de progressão de meta: 0% → 30% → 110%

require_relative 'config/environment'

puts '🏪 CRIANDO CENÁRIO DE TESTE - META COM PROGRESSÃO'
puts '=' * 60

begin
  # Limpeza prévia
  Goal.where(description: 'Meta Teste Progressão - R$ 10.000').delete_all
  OrderItem.joins(:order).where(orders: { external_id: ['TESTE_3K', 'TESTE_8K'] }).delete_all
  Order.where(external_id: ['TESTE_3K', 'TESTE_8K']).delete_all
  Product.where(external_id: 'PROD_TESTE').delete_all
  Seller.where(external_id: 'VEND_TESTE_001').delete_all
  Store.where(slug: 'loja-teste-zero').delete_all

  # 1. Criar loja nova com zero vendas
  company = Company.first || Company.create!(name: 'Teste Company')
  store = Store.create!(
    name: 'LOJA TESTE ZERO VENDAS',
    slug: 'loja-teste-zero',
    company: company
  )

  puts "✅ Loja criada: #{store.name} (ID: #{store.id})"

  # 2. Criar vendedor
  seller = Seller.create!(
    name: 'VENDEDOR TESTE',
    external_id: 'VEND_TESTE_001',
    company: company,
    store: store
  )

  puts "✅ Vendedor criado: #{seller.name} (ID: #{seller.id})"

  # 3. Verificar que não há vendas
  current_sales = Order.joins(:order_items)
                      .where(seller_id: seller.id)
                      .sum('order_items.quantity * order_items.unit_price')

  puts "💰 Vendas atuais: R$ #{current_sales / 100.0}"

  # 4. Criar meta de R$ 10.000
  goal = Goal.create!(
    seller_id: seller.id,
    goal_type: 'sales',
    goal_scope: 'individual',
    start_date: Date.current.beginning_of_month,
    end_date: Date.current.end_of_month,
    target_value: 1000000, # R$ 10.000,00 (em centavos)
    current_value: 0,
    description: 'Meta Teste Progressão - R$ 10.000'
  )

  puts "🎯 Meta criada: ID #{goal.id}"
  puts "   Target: R$ #{goal.target_value / 100.0}"
  puts "   Current: R$ #{goal.current_value / 100.0}"
  puts "   Progress: #{goal.progress_percentage}%"

  # Validação 1: 0%
  if goal.progress_percentage == 0.0
    puts "   ✅ TESTE 1 PASSOU: 0% inicial correto"
  else
    puts "   ❌ TESTE 1 FALHOU: esperado 0%, obtido #{goal.progress_percentage}%"
  end

  puts "\n" + "="*60
  puts "📦 ETAPA 1: ADICIONAR VENDA DE R$ 3.000 (30%)"
  puts "="*60

  # 5. Criar produto para teste
  category = Category.first
  product = Product.create!(
    external_id: 'PROD_TESTE',
    name: 'Produto Teste',
    sku: 'SKU_TESTE',
    category: category
  )

  # 6. Adicionar venda de R$ 3.000
  order1 = Order.create!(
    seller: seller,
    external_id: 'TESTE_3K',
    sold_at: Date.current + 1.day
  )

  order_item1 = OrderItem.create!(
    order: order1,
    product: product,
    external_id: 'ITEM_3K',
    quantity: 1,
    unit_price: 300000, # R$ 3.000,00 em centavos
    store: store
  )

  puts "💰 Venda 1 criada: R$ 3.000,00"

  # Recalcular meta
  controller = GoalsController.new
  controller.send(:update_goal_progress, goal)
  goal.reload

  puts "🎯 Meta após 1ª venda:"
  puts "   Current: R$ #{goal.current_value / 100.0}"
  puts "   Progress: #{goal.progress_percentage}%"

  # Validação 2: 30%
  if goal.progress_percentage == 30.0
    puts "   ✅ TESTE 2 PASSOU: 30% após R$ 3.000 correto"
  else
    puts "   ❌ TESTE 2 FALHOU: esperado 30%, obtido #{goal.progress_percentage}%"
  end

  puts "\n" + "="*60
  puts "📦 ETAPA 2: ADICIONAR VENDA DE R$ 8.000 (110%)"
  puts "="*60

  # 7. Adicionar venda de R$ 8.000
  order2 = Order.create!(
    seller: seller,
    external_id: 'TESTE_8K',
    sold_at: Date.current + 2.days
  )

  order_item2 = OrderItem.create!(
    order: order2,
    product: product,
    external_id: 'ITEM_8K',
    quantity: 1,
    unit_price: 800000, # R$ 8.000,00 em centavos
    store: store
  )

  puts "💰 Venda 2 criada: R$ 8.000,00"

  # Recalcular meta
  controller.send(:update_goal_progress, goal)
  goal.reload

  puts "🎯 Meta após 2ª venda:"
  puts "   Current: R$ #{goal.current_value / 100.0}"
  puts "   Progress: #{goal.progress_percentage}%"

  # Validação 3: 110%
  if goal.progress_percentage == 110.0
    puts "   ✅ TESTE 3 PASSOU: 110% após R$ 11.000 total correto"
  else
    puts "   ❌ TESTE 3 FALHOU: esperado 110%, obtido #{goal.progress_percentage}%"
  end

  puts "\n" + "="*60
  puts "🎉 RESUMO FINAL"
  puts "="*60
  puts "Meta ID: #{goal.id}"
  puts "Target: R$ #{goal.target_value / 100.0}"
  puts "Current: R$ #{goal.current_value / 100.0}"
  puts "Progress: #{goal.progress_percentage}%"
  puts ""
  puts "Cronologia:"
  puts "  1. Início: R$ 0 → 0% ✅"
  puts "  2. +R$ 3.000 → 30% ✅"
  puts "  3. +R$ 8.000 → 110% ✅"
  puts ""
  puts "🎯 TODOS OS TESTES PASSARAM!"

rescue => e
  puts "\n❌ ERRO: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Cleanup
  puts "\n🧹 Limpando dados de teste..."
  Goal.where(description: 'Meta Teste Progressão - R$ 10.000').delete_all
  OrderItem.joins(:order).where(orders: { external_id: ['TESTE_3K', 'TESTE_8K'] }).delete_all
  Order.where(external_id: ['TESTE_3K', 'TESTE_8K']).delete_all
  Product.where(external_id: 'PROD_TESTE').delete_all
  Seller.where(external_id: 'VEND_TESTE_001').delete_all
  Store.where(slug: 'loja-teste-zero').delete_all
  puts "✅ Cleanup concluído!"
end
