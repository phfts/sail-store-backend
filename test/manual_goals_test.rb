#!/usr/bin/env ruby
# Teste manual rápido para validar cálculos das metas

require_relative 'test_helper'

class ManualGoalsTest
  def self.run
    puts "🧪 TESTE MANUAL - CÁLCULO DE METAS"
    puts "=" * 50
    
    begin
      # Limpar dados de teste
      cleanup_test_data
      
      # Criar dados de teste
      company, store, seller, user = create_test_data
      
      # Criar pedidos para teste
      create_test_orders(seller, store)
      
      # Testar cálculo individual
      test_individual_goal_calculation(seller)
      
      # Testar cálculo por loja
      test_store_wide_goal_calculation(store)
      
      # Testar método update_goal_progress
      test_update_goal_progress_method(user, seller, store)
      
      puts "\n✅ TODOS OS TESTES PASSARAM!"
      
    rescue => e
      puts "\n❌ ERRO: #{e.message}"
      puts e.backtrace.first(3)
    ensure
      cleanup_test_data
    end
  end
  
  def self.cleanup_test_data
    Goal.where(description: 'TESTE').delete_all
    OrderItem.joins(:order).where(orders: { external_id: ['TEST001', 'TEST002'] }).delete_all
    Order.where(external_id: ['TEST001', 'TEST002']).delete_all
    Product.where(external_id: 'PROD001').delete_all
    User.where(email: 'teste@teste.com').delete_all
    Seller.where(name: 'TESTE SELLER').delete_all
    Store.where(name: 'TESTE STORE').delete_all
    Company.where(name: 'TESTE COMPANY').delete_all
  end
  
  def self.create_test_data
    company = Company.create!(name: 'TESTE COMPANY')
    store = Store.create!(name: 'TESTE STORE', company: company, slug: 'teste-store')
    seller = Seller.create!(name: 'TESTE SELLER', external_id: 'TESTE001', company: company, store: store)
    user = User.create!(email: 'teste@teste.com', password: 'password', password_confirmation: 'password')
    
    # Associar user ao seller
    seller.update!(user: user)
    
    puts "📋 Dados criados:"
    puts "  Company: #{company.name} (ID: #{company.id})"
    puts "  Store: #{store.name} (ID: #{store.id})"
    puts "  Seller: #{seller.name} (ID: #{seller.id})"
    puts "  User: #{user.email} (ID: #{user.id})"
    
    [company, store, seller, user]
  end
  
  def self.create_test_orders(seller, store)
    # Criar produto para teste
    product = Product.create!(
      external_id: 'PROD001',
      name: 'Produto Teste'
    )
    
    # Ordem 1 - R$ 30.000  
    order1 = Order.create!(
      seller: seller,
      store: store,
      external_id: 'TEST001',
      sold_at: '2025-08-10 10:00:00'
    )
    
    OrderItem.create!(
      order: order1,
      product: product,
      external_id: 'ITEM001',
      quantity: 2,
      unit_price: 15000, # R$ 150,00 cada = R$ 300,00 total
      store: store
    )
    
    # Ordem 2 - R$ 25.000
    order2 = Order.create!(
      seller: seller,
      store: store,
      external_id: 'TEST002',
      sold_at: '2025-08-15 14:30:00'
    )
    
    OrderItem.create!(
      order: order2,
      product: product,
      external_id: 'ITEM002',
      quantity: 1,
      unit_price: 25000, # R$ 250,00
      store: store
    )
    
    total_sales = 30000 + 25000
    puts "💰 Pedidos criados: R$ #{total_sales / 100.0} total"
    
    total_sales
  end
  
  def self.test_individual_goal_calculation(seller)
    puts "\n🎯 TESTE 1: Meta Individual"
    
    # Criar meta individual
    goal = Goal.create!(
      seller_id: seller.id,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 40000, # R$ 400,00
      description: 'TESTE'
    )
    
    puts "  Meta criada: ID #{goal.id}, Target: R$ #{goal.target_value / 100.0}"
    
    # Calcular vendas manualmente
    manual_sales = Order.joins(:order_items)
                       .where(seller_id: seller.id)
                       .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                              goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                       .sum('order_items.quantity * order_items.unit_price')
    
    puts "  Vendas calculadas manualmente: R$ #{manual_sales / 100.0}"
    
    # Simular update_goal_progress
    goal.update_column(:current_value, manual_sales)
    goal.reload
    
    puts "  Current value na meta: R$ #{goal.current_value / 100.0}"
    puts "  Progress: #{goal.progress_percentage}%"
    
    # Validações
    expected_sales = 55000 # R$ 550,00 (300 + 250)
    assert_equal expected_sales, manual_sales, "Vendas calculadas incorretamente"
    assert_equal expected_sales, goal.current_value, "Current value incorreto"
    assert_equal 137.5, goal.progress_percentage, "Progress percentage incorreto"
    
    puts "  ✅ Meta individual calculada corretamente!"
    goal
  end
  
  def self.test_store_wide_goal_calculation(store)
    puts "\n🏪 TESTE 2: Meta por Loja"
    
    # Criar meta por loja
    goal = Goal.create!(
      seller_id: nil,
      goal_type: 'sales',
      goal_scope: 'store_wide',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 50000, # R$ 500,00
      description: 'TESTE'
    )
    
    puts "  Meta criada: ID #{goal.id}, Target: R$ #{goal.target_value / 100.0}"
    
    # Calcular vendas manualmente
    manual_sales = Order.joins(:order_items, :seller)
                       .where(sellers: { store_id: store.id })
                       .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                              goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                       .sum('order_items.quantity * order_items.unit_price')
    
    puts "  Vendas calculadas manualmente: R$ #{manual_sales / 100.0}"
    
    # Simular update_goal_progress
    goal.update_column(:current_value, manual_sales)
    goal.reload
    
    puts "  Current value na meta: R$ #{goal.current_value / 100.0}"
    puts "  Progress: #{goal.progress_percentage}%"
    
    # Validações
    expected_sales = 55000 # R$ 550,00
    assert_equal expected_sales, manual_sales, "Vendas por loja calculadas incorretamente"
    assert_equal expected_sales, goal.current_value, "Current value por loja incorreto"
    assert_equal 110.0, goal.progress_percentage, "Progress percentage por loja incorreto"
    
    puts "  ✅ Meta por loja calculada corretamente!"
    goal
  end
  
  def self.test_update_goal_progress_method(user, seller, store)
    puts "\n⚙️  TESTE 3: Método update_goal_progress"
    
    # Criar controller fake para testar o método
    controller = GoalsController.new
    controller.instance_variable_set(:@current_user, user)
    
    # Definir current_user
    def controller.current_user
      @current_user
    end
    
    # Criar meta para teste
    goal = Goal.create!(
      seller_id: seller.id,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 60000,
      current_value: 0, # Começar com 0
      description: 'TESTE'
    )
    
    puts "  Meta antes: Current = R$ #{goal.current_value / 100.0}"
    
    # Chamar o método privado
    controller.send(:update_goal_progress, goal)
    goal.reload
    
    puts "  Meta depois: Current = R$ #{goal.current_value / 100.0}"
    puts "  Progress: #{goal.progress_percentage}%"
    
    # Validação
    expected_sales = 55000
    assert_equal expected_sales, goal.current_value, "Método update_goal_progress falhou"
    
    puts "  ✅ Método update_goal_progress funcionando!"
  end
  
  def self.assert_equal(expected, actual, message)
    unless expected == actual
      raise "#{message}: esperado #{expected}, obtido #{actual}"
    end
  end
end

# Executar se chamado diretamente
if __FILE__ == $0
  ManualGoalsTest.run
end
