require 'test_helper'

class SalesEndpointsTest < ActionDispatch::IntegrationTest
  def setup
    # Cleanup dados de teste anteriores
    cleanup_test_data
    
    # Criar estrutura de teste
    @company = Company.create!(name: 'Empresa Teste Vendas')
    @store = Store.create!(
      name: 'Loja Teste Vendas',
      slug: 'loja-teste-vendas',
      company: @company
    )
    
    # Criar dois vendedores
    @seller1 = Seller.create!(
      name: 'Vendedor A',
      external_id: 'VEND_A_001',
      company: @company,
      store: @store
    )
    
    @seller2 = Seller.create!(
      name: 'Vendedor B', 
      external_id: 'VEND_B_001',
      company: @company,
      store: @store
    )
    
    # Criar usuário admin para testes
    @admin_user = User.create!(
      email: 'admin@teste.com',
      password: 'password123',
      password_confirmation: 'password123',
      admin: true
    )
    
    # Criar produto para teste
    @category = Category.first || Category.create!(name: 'Categoria Teste', description: 'Teste', company: @company)
    @product = Product.create!(
      external_id: 'PROD_TESTE_VENDAS',
      name: 'Produto Teste Vendas',
      sku: 'SKU_TESTE_VENDAS',
      category: @category
    )
    
    # Criar vendas: Vendedor A = R$ 5.000, Vendedor B = R$ 7.000
    create_sales_data
    
    puts "Setup concluído: Loja ID #{@store.id}, Vendedor A: R$ 50,00, Vendedor B: R$ 70,00"
  end
  
  def teardown
    cleanup_test_data
  end
  
  # Teste 1: Endpoint de ranking individual
  test "sellers ranking endpoint returns correct individual sales" do
    # Login como admin
    post '/auth/login', params: { email: @admin_user.email, password: 'password123' }
    assert_response :success
    
    token = JSON.parse(response.body)['token']
    
    # Chamar endpoint de ranking
    get "/stores/#{@store.slug}/sellers/ranking", 
        headers: { 'Authorization' => "Bearer #{token}" }
    
    assert_response :success
    
    ranking_data = JSON.parse(response.body)
    assert_not_empty ranking_data
    
    # Verificar vendas individuais
    vendedor_a_data = ranking_data.find { |s| s['seller']['name'] == 'Vendedor A' }
    vendedor_b_data = ranking_data.find { |s| s['seller']['name'] == 'Vendedor B' }
    
    assert_not_nil vendedor_a_data, "Vendedor A deve aparecer no ranking"
    assert_not_nil vendedor_b_data, "Vendedor B deve aparecer no ranking"
    
    # Validar vendas exatas (em centavos)
    assert_equal 500000, vendedor_a_data['sales']['current'], "Vendedor A deve ter R$ 5.000"
    assert_equal 700000, vendedor_b_data['sales']['current'], "Vendedor B deve ter R$ 7.000"
    
    puts "✅ Ranking endpoint: Vendedor A = R$ #{vendedor_a_data['sales']['current'] / 100.0}, Vendedor B = R$ #{vendedor_b_data['sales']['current'] / 100.0}"
  end
  
  # Teste 2: Endpoint de dashboard da loja
  test "store dashboard endpoint returns correct total sales" do
    # Login como admin
    post '/auth/login', params: { email: @admin_user.email, password: 'password123' }
    token = JSON.parse(response.body)['token']
    
    # Chamar endpoint de dashboard
    get "/stores/#{@store.slug}/dashboard",
        headers: { 'Authorization' => "Bearer #{token}" }
    
    assert_response :success
    
    dashboard_data = JSON.parse(response.body)
    
    # Verificar vendas totais da loja (R$ 5.000 + R$ 7.000 = R$ 12.000)
    current_week_sales = dashboard_data['sales']['currentWeek']
    
    expected_total = 1200000 # R$ 12.000 em centavos
    assert_equal expected_total, current_week_sales, "Total da loja deve ser R$ 12.000"
    
    puts "✅ Dashboard endpoint: Total da loja = R$ #{current_week_sales / 100.0}"
  end
  
  # Teste 3: Endpoint beta individual
  test "beta kpis endpoint returns correct individual sales" do
    # Chamar endpoint beta (sem autenticação necessária)
    get "/beta/sellers/#{@seller1.id}/kpis"
    
    assert_response :success
    
    kpi_data = JSON.parse(response.body)
    
    # Verificar vendas brutas do vendedor A
    vendas_brutas_semana = kpi_data['vendas_brutas_semana']
    
    expected_sales = 500000 # R$ 5.000 em centavos
    assert_equal expected_sales, vendas_brutas_semana, "Vendedor A deve ter R$ 5.000 na semana"
    
    puts "✅ Beta KPIs endpoint: Vendedor A vendas semana = R$ #{vendas_brutas_semana / 100.0}"
  end
  
  # Teste 4: Verificação de consistência entre endpoints
  test "sales consistency across all endpoints" do
    # Login
    post '/auth/login', params: { email: @admin_user.email, password: 'password123' }
    token = JSON.parse(response.body)['token']
    
    # 1. Obter vendas do ranking
    get "/stores/#{@store.slug}/sellers/ranking", 
        headers: { 'Authorization' => "Bearer #{token}" }
    ranking_data = JSON.parse(response.body)
    
    vendedor_a_ranking = ranking_data.find { |s| s['seller']['name'] == 'Vendedor A' }['sales']['current']
    vendedor_b_ranking = ranking_data.find { |s| s['seller']['name'] == 'Vendedor B' }['sales']['current']
    total_ranking = vendedor_a_ranking + vendedor_b_ranking
    
    # 2. Obter vendas do dashboard
    get "/stores/#{@store.slug}/dashboard",
        headers: { 'Authorization' => "Bearer #{token}" }
    dashboard_data = JSON.parse(response.body)
    total_dashboard = dashboard_data['sales']['currentWeek']
    
    # 3. Obter vendas do beta (vendedor A)
    get "/beta/sellers/#{@seller1.id}/kpis"
    kpi_data = JSON.parse(response.body)
    vendedor_a_beta = kpi_data['vendas_brutas_semana']
    
    # Verificar consistência
    assert_equal total_ranking, total_dashboard, 
                 "Total do ranking (#{total_ranking}) deve ser igual ao dashboard (#{total_dashboard})"
    
    assert_equal vendedor_a_ranking, vendedor_a_beta,
                 "Vendas do Vendedor A no ranking (#{vendedor_a_ranking}) devem ser iguais ao beta (#{vendedor_a_beta})"
    
    # Verificar valores exatos
    assert_equal 500000, vendedor_a_ranking, "Vendedor A: R$ 5.000"
    assert_equal 700000, vendedor_b_ranking, "Vendedor B: R$ 7.000"  
    assert_equal 1200000, total_dashboard, "Total loja: R$ 12.000"
    
    puts "✅ Consistência verificada:"
    puts "   Vendedor A: R$ #{vendedor_a_ranking / 100.0} (ranking) = R$ #{vendedor_a_beta / 100.0} (beta)"
    puts "   Vendedor B: R$ #{vendedor_b_ranking / 100.0} (ranking)"
    puts "   Total Loja: R$ #{total_dashboard / 100.0} (dashboard) = R$ #{total_ranking / 100.0} (soma ranking)"
  end
  
  private
  
  def create_sales_data
    # Vendas do Vendedor A: R$ 5.000 (50.000 centavos)
    order_a = Order.create!(
      seller: @seller1,
      external_id: 'ORDER_A_5K',
      sold_at: Date.current.beginning_of_week + 1.day
    )
    
    OrderItem.create!(
      order: order_a,
      product: @product,
      external_id: 'ITEM_A_5K',
      quantity: 1,
      unit_price: 500000, # R$ 5.000,00 em centavos
      store: @store
    )
    
    # Vendas do Vendedor B: R$ 7.000 (70.000 centavos)
    order_b = Order.create!(
      seller: @seller2,
      external_id: 'ORDER_B_7K',
      sold_at: Date.current.beginning_of_week + 2.days
    )
    
    OrderItem.create!(
      order: order_b,
      product: @product,
      external_id: 'ITEM_B_7K',
      quantity: 1,
      unit_price: 700000, # R$ 7.000,00 em centavos
      store: @store
    )
    
    puts "Vendas criadas: Vendedor A = R$ 50,00, Vendedor B = R$ 70,00"
  end
  
  def cleanup_test_data
    # Ordem específica para evitar constraint violations
    OrderItem.joins(:order).where(orders: { external_id: ['ORDER_A_5K', 'ORDER_B_7K'] }).delete_all
    Order.where(external_id: ['ORDER_A_5K', 'ORDER_B_7K']).delete_all
    Product.where(external_id: 'PROD_TESTE_VENDAS').delete_all
    User.where(email: 'admin@teste.com').delete_all
    Seller.where(external_id: ['VEND_A_001', 'VEND_B_001']).delete_all
    Store.where(slug: 'loja-teste-vendas').delete_all
    Company.where(name: 'Empresa Teste Vendas').delete_all
  rescue => e
    # Ignorar erros de cleanup
    puts "Aviso no cleanup: #{e.message}"
  end
end
