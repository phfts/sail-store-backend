require 'test_helper'

class SalesValidationTest < ActionDispatch::IntegrationTest
  # Desabilitar fixtures automáticas que estão causando problemas
  self.use_transactional_tests = false
  
  def self.fixtures(*table_names)
    # Sobrescrever para não carregar fixtures
  end
  
  def setup
    # Limpar dados anteriores
    cleanup_test_data
    
    # Criar dados de teste sem usar fixtures
    create_test_environment
    
    puts "\n🧪 Setup: Vendedor A (R$ 50,00), Vendedor B (R$ 70,00), Total: R$ 120,00"
  end
  
  def teardown
    cleanup_test_data
  end
  
  # Teste 1: Endpoint de ranking individual
  test "sellers ranking endpoint shows correct individual sales" do
    token = login_as_admin
    
    get "/stores/#{@store.slug}/sellers/ranking", 
        headers: auth_headers(token)
    
    assert_response :success
    ranking_data = JSON.parse(response.body)
    
    # Verificar se é um array
    assert ranking_data.is_a?(Array), "Response should be an array"
    assert_not ranking_data.empty?, "Ranking should not be empty"
    
    # Encontrar vendedores
    seller_a_data = ranking_data.find { |s| s['seller']['name'] == 'Vendedor A Test' }
    seller_b_data = ranking_data.find { |s| s['seller']['name'] == 'Vendedor B Test' }
    
    assert_not_nil seller_a_data, "Vendedor A should appear in ranking"
    assert_not_nil seller_b_data, "Vendedor B should appear in ranking"
    
    # Validar vendas individuais (em centavos)
    assert_equal 500000, seller_a_data['sales']['current'], "Vendedor A should have R$ 5.000"
    assert_equal 700000, seller_b_data['sales']['current'], "Vendedor B should have R$ 7.000"
    
    puts "✅ Ranking: A=R$#{seller_a_data['sales']['current']/100.0}, B=R$#{seller_b_data['sales']['current']/100.0}"
  end
  
  # Teste 2: Endpoint de dashboard da loja
  test "store dashboard endpoint shows correct total sales" do
    token = login_as_admin
    
    get "/stores/#{@store.slug}/dashboard",
        headers: auth_headers(token)
    
    assert_response :success
    dashboard_data = JSON.parse(response.body)
    
    # Verificar estrutura da resposta
    assert dashboard_data.key?('sales'), "Dashboard should have sales data"
    assert dashboard_data['sales'].key?('currentWeek'), "Should have current week sales"
    
    # Verificar total da semana (R$ 5.000 + R$ 7.000 = R$ 12.000)
    current_week_sales = dashboard_data['sales']['currentWeek']
    expected_total = 1200000 # R$ 12.000 em centavos
    
    assert_equal expected_total, current_week_sales, "Store total should be R$ 12.000"
    
    puts "✅ Dashboard: Total=R$#{current_week_sales/100.0}"
  end
  
  # Teste 3: Endpoint beta KPIs individual
  test "beta kpis endpoint shows correct individual sales" do
    get "/beta/sellers/#{@seller_a.id}/kpis"
    
    assert_response :success
    kpi_data = JSON.parse(response.body)
    
    # Verificar se tem dados de vendas
    assert kpi_data.key?('vendas_brutas_semana'), "Should have weekly gross sales"
    
    vendas_semana = kpi_data['vendas_brutas_semana']
    expected_sales = 500000 # R$ 5.000 em centavos
    
    assert_equal expected_sales, vendas_semana, "Vendedor A should have R$ 5.000 in weekly sales"
    
    puts "✅ Beta KPIs: VendedorA=R$#{vendas_semana/100.0}"
  end
  
  # Teste 4: Consistência entre todos os endpoints
  test "sales consistency across all endpoints" do
    token = login_as_admin
    
    # 1. Obter dados do ranking
    get "/stores/#{@store.slug}/sellers/ranking",
        headers: auth_headers(token)
    assert_response :success
    ranking_data = JSON.parse(response.body)
    
    seller_a_ranking = ranking_data.find { |s| s['seller']['name'] == 'Vendedor A Test' }['sales']['current']
    seller_b_ranking = ranking_data.find { |s| s['seller']['name'] == 'Vendedor B Test' }['sales']['current']
    total_from_ranking = seller_a_ranking + seller_b_ranking
    
    # 2. Obter dados do dashboard
    get "/stores/#{@store.slug}/dashboard",
        headers: auth_headers(token)
    assert_response :success
    dashboard_data = JSON.parse(response.body)
    total_from_dashboard = dashboard_data['sales']['currentWeek']
    
    # 3. Obter dados do beta
    get "/beta/sellers/#{@seller_a.id}/kpis"
    assert_response :success
    kpi_data = JSON.parse(response.body)
    seller_a_from_beta = kpi_data['vendas_brutas_semana']
    
    # Verificar consistência entre endpoints
    assert_equal total_from_ranking, total_from_dashboard,
                 "Total from ranking should equal dashboard total"
    
    assert_equal seller_a_ranking, seller_a_from_beta,
                 "Seller A sales should be consistent between ranking and beta"
    
    # Verificar valores absolutos
    assert_equal 500000, seller_a_ranking, "Vendedor A: R$ 5.000"
    assert_equal 700000, seller_b_ranking, "Vendedor B: R$ 7.000"
    assert_equal 1200000, total_from_dashboard, "Total store: R$ 12.000"
    
    puts "✅ Consistency validated:"
    puts "   A: R$#{seller_a_ranking/100.0} (ranking) = R$#{seller_a_from_beta/100.0} (beta)"
    puts "   B: R$#{seller_b_ranking/100.0} (ranking)"
    puts "   Total: R$#{total_from_dashboard/100.0} (dashboard) = R$#{total_from_ranking/100.0} (sum)"
  end
  
  # Teste 5: Validação de cálculos matemáticos
  test "mathematical validation of sales calculations" do
    # Verificar cálculo direto no banco
    seller_a_sales = Order.joins(:order_items)
                          .where(seller_id: @seller_a.id)
                          .where('orders.sold_at >= ? AND orders.sold_at <= ?',
                                 Date.current.beginning_of_week, Date.current.end_of_week)
                          .sum('order_items.quantity * order_items.unit_price')
    
    seller_b_sales = Order.joins(:order_items)
                          .where(seller_id: @seller_b.id)
                          .where('orders.sold_at >= ? AND orders.sold_at <= ?',
                                 Date.current.beginning_of_week, Date.current.end_of_week)
                          .sum('order_items.quantity * order_items.unit_price')
    
    store_total_sales = Order.joins(:order_items, :seller)
                            .where(sellers: { store_id: @store.id })
                            .where('orders.sold_at >= ? AND orders.sold_at <= ?',
                                   Date.current.beginning_of_week, Date.current.end_of_week)
                            .sum('order_items.quantity * order_items.unit_price')
    
    # Validar cálculos diretos
    assert_equal 500000, seller_a_sales, "Direct DB calculation for Seller A"
    assert_equal 700000, seller_b_sales, "Direct DB calculation for Seller B"
    assert_equal 1200000, store_total_sales, "Direct DB calculation for store total"
    assert_equal seller_a_sales + seller_b_sales, store_total_sales, "Sum should equal total"
    
    puts "✅ Mathematical validation:"
    puts "   Direct DB - A: R$#{seller_a_sales/100.0}, B: R$#{seller_b_sales/100.0}, Total: R$#{store_total_sales/100.0}"
  end
  
  private
  
  def create_test_environment
    # Criar company
    @company = Company.create!(name: 'Test Company Sales')
    
    # Criar store
    @store = Store.create!(
      name: 'Test Store Sales',
      slug: 'test-store-sales',
      company: @company
    )
    
    # Criar vendedores
    @seller_a = Seller.create!(
      name: 'Vendedor A Test',
      external_id: 'SELLER_A_TEST',
      company: @company,
      store: @store
    )
    
    @seller_b = Seller.create!(
      name: 'Vendedor B Test',
      external_id: 'SELLER_B_TEST',
      company: @company,
      store: @store
    )
    
    # Criar admin user
    @admin = User.create!(
      email: 'admin.sales.test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      admin: true
    )
    
    # Criar produto
    category = Category.first
    if category.nil?
      category = Category.create!(name: 'Test Category', description: 'Test', company: @company)
    end
    
    @product = Product.create!(
      external_id: 'PRODUCT_SALES_TEST',
      name: 'Test Product Sales',
      sku: 'SKU_SALES_TEST',
      category: category
    )
    
    # Criar vendas
    create_sales_data
  end
  
  def create_sales_data
    # Vendedor A: R$ 5.000 na semana atual
    order_a = Order.create!(
      seller: @seller_a,
      external_id: 'ORDER_A_SALES_TEST',
      sold_at: Date.current.beginning_of_week + 1.day
    )
    
    OrderItem.create!(
      order: order_a,
      product: @product,
      external_id: 'ITEM_A_SALES_TEST',
      quantity: 1,
      unit_price: 500000, # R$ 5.000 em centavos
      store: @store
    )
    
    # Vendedor B: R$ 7.000 na semana atual
    order_b = Order.create!(
      seller: @seller_b,
      external_id: 'ORDER_B_SALES_TEST',
      sold_at: Date.current.beginning_of_week + 2.days
    )
    
    OrderItem.create!(
      order: order_b,
      product: @product,
      external_id: 'ITEM_B_SALES_TEST',
      quantity: 1,
      unit_price: 700000, # R$ 7.000 em centavos
      store: @store
    )
  end
  
  def login_as_admin
    post '/auth/login', params: {
      email: @admin.email,
      password: 'password123'
    }
    
    assert_response :success
    JSON.parse(response.body)['token']
  end
  
  def auth_headers(token)
    { 'Authorization' => "Bearer #{token}" }
  end
  
  def cleanup_test_data
    # Limpeza em ordem correta para evitar constraint violations
    begin
      OrderItem.joins(:order).where(orders: { external_id: ['ORDER_A_SALES_TEST', 'ORDER_B_SALES_TEST'] }).delete_all
      Order.where(external_id: ['ORDER_A_SALES_TEST', 'ORDER_B_SALES_TEST']).delete_all
      Product.where(external_id: 'PRODUCT_SALES_TEST').delete_all
      User.where(email: 'admin.sales.test@example.com').delete_all
      Seller.where(external_id: ['SELLER_A_TEST', 'SELLER_B_TEST']).delete_all
      Store.where(slug: 'test-store-sales').delete_all
      Company.where(name: 'Test Company Sales').delete_all
    rescue => e
      # Ignorar erros de cleanup - pode ser que os dados já tenham sido removidos
      puts "Warning during cleanup: #{e.message}" if Rails.env.test?
    end
  end
end
