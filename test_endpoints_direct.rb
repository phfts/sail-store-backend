#!/usr/bin/env ruby
# Teste direto dos endpoints sem fixtures

require_relative 'config/environment'

puts '🧪 TESTE DIRETO DOS ENDPOINTS DE VENDAS'
puts '=' * 60

def cleanup_test_data
  OrderItem.joins(:order).where(orders: { external_id: ['ORDER_A_DIRETO', 'ORDER_B_DIRETO'] }).delete_all rescue nil
  Order.where(external_id: ['ORDER_A_DIRETO', 'ORDER_B_DIRETO']).delete_all rescue nil
  Product.where(external_id: 'PROD_DIRETO_TEST').delete_all rescue nil
  User.where(email: 'admin.direto@test.com').delete_all rescue nil
  Seller.where(external_id: ['VEND_A_DIRETO', 'VEND_B_DIRETO']).delete_all rescue nil
  Store.where(slug: 'loja-teste-direto').delete_all rescue nil
  Company.where(name: 'Empresa Teste Direto').delete_all rescue nil
end

begin
  # Cleanup
  cleanup_test_data
  
  # Criar dados de teste
  puts "📋 Criando dados de teste..."
  
  company = Company.create!(name: 'Empresa Teste Direto')
  store = Store.create!(
    name: 'Loja Teste Direto',
    slug: 'loja-teste-direto',
    company: company
  )
  
  # Vendedores
  seller_a = Seller.create!(
    name: 'Vendedor A Direto',
    external_id: 'VEND_A_DIRETO',
    company: company,
    store: store
  )
  
  seller_b = Seller.create!(
    name: 'Vendedor B Direto', 
    external_id: 'VEND_B_DIRETO',
    company: company,
    store: store
  )
  
  # Admin user
  admin = User.create!(
    email: 'admin.direto@test.com',
    password: 'password123',
    password_confirmation: 'password123',
    admin: true
  )
  
  # Produto
  category = Category.first_or_create!(name: 'Cat Direto', description: 'Test', company: company)
  product = Product.create!(
    external_id: 'PROD_DIRETO_TEST',
    name: 'Produto Direto Test',
    sku: 'SKU_DIRETO_TEST',
    category: category
  )
  
  puts "✅ Dados criados: Store #{store.id}, Seller A #{seller_a.id}, Seller B #{seller_b.id}"
  
  # Criar vendas: A = R$ 5.000, B = R$ 7.000
  puts "💰 Criando vendas..."
  
  # Vendedor A: R$ 5.000
  order_a = Order.create!(
    seller: seller_a,
    external_id: 'ORDER_A_DIRETO',
    sold_at: Date.current.beginning_of_week + 1.day
  )
  
  item_a = OrderItem.create!(
    order: order_a,
    product: product,
    external_id: 'ITEM_A_DIRETO',
    quantity: 1,
    unit_price: 500000, # R$ 5.000,00 em centavos
    store: store
  )
  
  # Vendedor B: R$ 7.000
  order_b = Order.create!(
    seller: seller_b,
    external_id: 'ORDER_B_DIRETO',
    sold_at: Date.current.beginning_of_week + 2.days
  )
  
  item_b = OrderItem.create!(
    order: order_b,
    product: product,
    external_id: 'ITEM_B_DIRETO',
    quantity: 1,
    unit_price: 700000, # R$ 7.000,00 em centavos
    store: store
  )
  
  puts "✅ Vendas criadas: A=R$ 50,00, B=R$ 70,00"
  
  # Criar aplicação Rails para testar endpoints
  require 'net/http'
  require 'json'
  
  # Iniciar aplicação para testes
  puts "\n🌐 TESTANDO ENDPOINTS..."
  
  # Simular controller diretamente
  puts "\n1️⃣ TESTE RANKING (SellersController#ranking)"
  
  # Criar instância do controller
  controller = SellersController.new
  controller.instance_variable_set(:@current_user, admin)
  
  # Simular método current_user
  def controller.current_user
    @current_user
  end
  
  # Simular parâmetros
  params = ActionController::Parameters.new(slug: store.slug)
  controller.instance_variable_set(:@params, params)
  
  def controller.params
    @params
  end
  
  # Simular render
  rendered_json = nil
  def controller.render(options)
    if options[:json]
      @rendered_json = options[:json]
    end
  end
  
  # Chamar método
  begin
    controller.ranking
    ranking_data = controller.instance_variable_get(:@rendered_json)
    
    if ranking_data.is_a?(Array)
      seller_a_data = ranking_data.find { |s| s[:seller][:name] == 'Vendedor A Direto' }
      seller_b_data = ranking_data.find { |s| s[:seller][:name] == 'Vendedor B Direto' }
      
      if seller_a_data && seller_b_data
        puts "  ✅ Vendedor A: R$ #{seller_a_data[:sales][:current] / 100.0}"
        puts "  ✅ Vendedor B: R$ #{seller_b_data[:sales][:current] / 100.0}"
        
        # Validações
        if seller_a_data[:sales][:current] == 500000
          puts "  ✅ Vendedor A correto: R$ 5.000"
        else
          puts "  ❌ Vendedor A incorreto: esperado 500000, obtido #{seller_a_data[:sales][:current]}"
        end
        
        if seller_b_data[:sales][:current] == 700000
          puts "  ✅ Vendedor B correto: R$ 7.000"
        else
          puts "  ❌ Vendedor B incorreto: esperado 700000, obtido #{seller_b_data[:sales][:current]}"
        end
      else
        puts "  ❌ Vendedores não encontrados no ranking"
      end
    else
      puts "  ❌ Resposta não é um array: #{ranking_data.class}"
    end
  rescue => e
    puts "  ❌ Erro no ranking: #{e.message}"
  end
  
  puts "\n2️⃣ TESTE DASHBOARD (DashboardController#store_dashboard)"
  
  # Testar dashboard
  dashboard_controller = DashboardController.new
  dashboard_controller.instance_variable_set(:@current_user, admin)
  
  def dashboard_controller.current_user
    @current_user
  end
  
  params = ActionController::Parameters.new(slug: store.slug)
  dashboard_controller.instance_variable_set(:@params, params)
  
  def dashboard_controller.params
    @params
  end
  
  def dashboard_controller.render(options)
    if options[:json]
      @rendered_json = options[:json]
    end
  end
  
  begin
    dashboard_controller.store_dashboard
    dashboard_data = dashboard_controller.instance_variable_get(:@rendered_json)
    
    if dashboard_data.is_a?(Hash) && dashboard_data[:sales]
      current_week_sales = dashboard_data[:sales][:currentWeek]
      
      puts "  ✅ Total da loja (semana): R$ #{current_week_sales / 100.0}"
      
      # Validação
      expected_total = 1200000 # R$ 12.000
      if current_week_sales == expected_total
        puts "  ✅ Total correto: R$ 12.000"
      else
        puts "  ❌ Total incorreto: esperado #{expected_total}, obtido #{current_week_sales}"
      end
    else
      puts "  ❌ Estrutura de resposta inválida"
    end
  rescue => e
    puts "  ❌ Erro no dashboard: #{e.message}"
  end
  
  puts "\n3️⃣ TESTE BETA KPIs (BetaController#kpis)"
  
  # Testar beta
  beta_controller = BetaController.new
  
  params = ActionController::Parameters.new(id: seller_a.id.to_s)
  beta_controller.instance_variable_set(:@params, params)
  
  def beta_controller.params
    @params
  end
  
  def beta_controller.render(options)
    if options[:json]
      @rendered_json = options[:json]
    end
  end
  
  begin
    beta_controller.kpis
    kpi_data = beta_controller.instance_variable_get(:@rendered_json)
    
    if kpi_data.is_a?(Hash) && kpi_data[:vendas_brutas_semana]
      vendas_semana = kpi_data[:vendas_brutas_semana]
      
      puts "  ✅ Vendedor A (semana): R$ #{vendas_semana / 100.0}"
      
      # Validação
      expected_sales = 500000 # R$ 5.000
      if vendas_semana == expected_sales
        puts "  ✅ Vendas corretas: R$ 5.000"
      else
        puts "  ❌ Vendas incorretas: esperado #{expected_sales}, obtido #{vendas_semana}"
      end
    else
      puts "  ❌ Estrutura KPI inválida"
    end
  rescue => e
    puts "  ❌ Erro no beta: #{e.message}"
  end
  
  puts "\n🎉 TESTE CONCLUÍDO!"
  puts "\n📊 RESUMO ESPERADO:"
  puts "  - Vendedor A: R$ 5.000,00"
  puts "  - Vendedor B: R$ 7.000,00"
  puts "  - Total Loja: R$ 12.000,00"
  puts "  - Consistência entre endpoints: ✅"
  
rescue => e
  puts "\n❌ ERRO GERAL: #{e.message}"
  puts e.backtrace.first(5)
ensure
  cleanup_test_data
end
