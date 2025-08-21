require 'test_helper'

class DashboardIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # Criar uma empresa
    @company = Company.create!(name: "Empresa Teste Dashboard")
    
    # Criar uma loja inicial sem vendedores
    @store1 = Store.create!(
      name: "Loja Teste Dashboard 1",
      slug: "loja-teste-dashboard-1",
      company: @company
    )
    
    # Criar uma segunda loja para testes de isolamento
    @store2 = Store.create!(
      name: "Loja Teste Dashboard 2", 
      slug: "loja-teste-dashboard-2",
      company: @company
    )
    
    # Criar um usuário admin
    @admin_user = User.create!(
      email: "admin@test.com",
      password: "password123",
      admin: true
    )
    
    # Gerar token JWT para autenticação
    @token = JWT.encode(
      { user_id: @admin_user.id, exp: 24.hours.from_now.to_i },
      ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
    )
  end

  test "dashboard shows correct seller count when adding sellers" do
    # Teste 1: Verificar que inicialmente há 0 vendedores
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 0, response_data["sellers"]["total"], 
                 "Inicialmente deve haver 0 vendedores"
    assert_equal 0, response_data["sellers"]["active"], 
                 "Inicialmente deve haver 0 vendedores ativos"
    
    # Teste 2: Adicionar um vendedor e verificar que há 1 vendedor
    seller1 = Seller.create!(
      name: "Vendedor Teste 1",
      store: @store1,
      company: @company,
      external_id: "seller_1"
    )
    
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 1, response_data["sellers"]["total"], 
                 "Deve haver 1 vendedor após adicionar um vendedor"
    assert_equal 1, response_data["sellers"]["active"], 
                 "Deve haver 1 vendedor ativo após adicionar um vendedor"
    
    # Teste 3: Adicionar dois vendedores em outra loja e verificar isolamento
    seller2 = Seller.create!(
      name: "Vendedor Teste 2",
      store: @store2,
      company: @company,
      external_id: "seller_2"
    )
    
    seller3 = Seller.create!(
      name: "Vendedor Teste 3", 
      store: @store2,
      company: @company,
      external_id: "seller_3"
    )
    
    # Verificar que a primeira loja ainda tem apenas 1 vendedor
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 1, response_data["sellers"]["total"], 
                 "Primeira loja deve continuar com 1 vendedor mesmo após adicionar vendedores em outra loja"
    assert_equal 1, response_data["sellers"]["active"], 
                 "Primeira loja deve continuar com 1 vendedor ativo"
    
    # Verificar que a segunda loja tem 2 vendedores
    get "/stores/#{@store2.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 2, response_data["sellers"]["total"], 
                 "Segunda loja deve ter 2 vendedores"
    assert_equal 2, response_data["sellers"]["active"], 
                 "Segunda loja deve ter 2 vendedores ativos"
  end

  test "dashboard shows correct seller data in sellersAnnualData" do
    # Adicionar um vendedor
    seller = Seller.create!(
      name: "Vendedor Teste",
      store: @store1,
      company: @company,
      external_id: "seller_test"
    )
    
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    # Verificar que o vendedor aparece nos dados anuais
    assert_equal 1, response_data["sellersAnnualData"].length,
                 "Deve haver 1 vendedor nos dados anuais"
    
    seller_data = response_data["sellersAnnualData"].first
    assert_equal seller.id, seller_data["id"],
                 "ID do vendedor deve corresponder"
    assert_equal seller.name, seller_data["name"],
                 "Nome do vendedor deve corresponder"
    assert_equal 0, seller_data["sales"],
                 "Vendedor sem vendas deve ter sales = 0"
    assert_equal 0, seller_data["net_sales"],
                 "Vendedor sem vendas deve ter net_sales = 0"
  end

  test "dashboard handles inactive sellers correctly" do
    # Adicionar um vendedor ativo
    active_seller = Seller.create!(
      name: "Vendedor Ativo",
      store: @store1,
      company: @company,
      external_id: "seller_active"
    )
    
    # Adicionar um vendedor inativo
    inactive_seller = Seller.create!(
      name: "Vendedor Inativo",
      store: @store1,
      company: @company,
      external_id: "seller_inactive"
    )
    
    # Inativar o segundo vendedor
    inactive_seller.deactivate!
    
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    # Verificar contadores
    assert_equal 2, response_data["sellers"]["total"],
                 "Total de vendedores deve incluir ativos e inativos"
    assert_equal 1, response_data["sellers"]["active"],
                 "Apenas vendedores ativos devem ser contados como ativos"
    
    # Verificar dados anuais (apenas vendedores ativos)
    assert_equal 1, response_data["sellersAnnualData"].length,
                 "Dados anuais devem incluir apenas vendedores ativos"
    assert_equal active_seller.name, response_data["sellersAnnualData"].first["name"],
                 "Dados anuais devem incluir apenas o vendedor ativo"
  end

  test "dashboard shows correct monthly sales when adding orders" do
    # Criar categoria para os produtos
    category = Category.create!(
      name: "Categoria Teste",
      company: @company,
      external_id: "cat_test"
    )
    
    # Criar produtos para as vendas
    product1 = Product.create!(
      name: "Produto Teste 1",
      category: category,
      external_id: "prod_1",
      sku: "SKU001"
    )
    
    product2 = Product.create!(
      name: "Produto Teste 2", 
      category: category,
      external_id: "prod_2",
      sku: "SKU002"
    )
    
    # Criar vendedores
    seller1 = Seller.create!(
      name: "Vendedor Loja 1",
      store: @store1,
      company: @company,
      external_id: "seller_loja1"
    )
    
    seller2 = Seller.create!(
      name: "Vendedor Loja 2",
      store: @store2,
      company: @company,
      external_id: "seller_loja2"
    )
    
    # Criar vendas no primeiro instante do mês atual
    current_month_start = Date.current.beginning_of_month.beginning_of_day
    
    # Venda de R$ 500,30 na primeira loja
    order1 = Order.create!(
      seller: seller1,
      sold_at: current_month_start,
      external_id: "order_1"
    )
    
    OrderItem.create!(
      order: order1,
      product: product1,
      store: @store1,
      quantity: 1,
      unit_price: 50030 # R$ 500,30 em centavos
    )
    
    # Venda de R$ 333,55 na segunda loja
    order2 = Order.create!(
      seller: seller2,
      sold_at: current_month_start,
      external_id: "order_2"
    )
    
    OrderItem.create!(
      order: order2,
      product: product2,
      store: @store2,
      quantity: 1,
      unit_price: 33355 # R$ 333,55 em centavos
    )
    
    # Verificar vendas da primeira loja
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 50030.0, response_data["sales"]["currentMonth"].to_f,
                 "Primeira loja deve ter vendas de R$ 500,30 no mês atual"
    
    # Verificar vendas da segunda loja
    get "/stores/#{@store2.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 33355.0, response_data["sales"]["currentMonth"].to_f,
                 "Segunda loja deve ter vendas de R$ 333,55 no mês atual"
    
    # Verificar que as vendas não se misturam entre as lojas
    get "/stores/#{@store1.slug}/dashboard", 
        headers: { "Authorization" => "Bearer #{@token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 50030.0, response_data["sales"]["currentMonth"].to_f,
                 "Primeira loja deve continuar com R$ 500,30 mesmo após verificar a segunda loja"
  end
end
