require 'test_helper'

class GoalsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Usuários
    @admin = users(:admin)
    @store_user = users(:one)  # Usar usuário que tem seller associado
    
    # Lojas
    @store = stores(:one)  # Usar a loja do usuário one
    
    # Vendedores
    @seller = sellers(:one)  # Usar o seller do usuário one
    
    # Criar pedidos para teste de cálculo
    create_test_orders
    
    # Metas
    @individual_goal = goals(:individual_goal)
    @store_wide_goal = goals(:store_wide_goal)
  end

  # === TESTES DE CÁLCULO DE PROGRESSO ===
  
  test "should calculate progress correctly for individual goal" do
    # Criar meta individual para período com vendas conhecidas
    goal = Goal.create!(
      seller_id: @seller.id,
      store_id: @store.id,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 50000,
      description: 'Meta teste individual'
    )
    
    login_as(@store_user)
    get '/goals', headers: @headers, as: :json
    assert_response :success
    
    # Verificar se o progresso foi calculado
    response_data = JSON.parse(response.body)
    test_goal = response_data.find { |g| g['id'] == goal.id }
    
    assert_not_nil test_goal, "Goal should be found in response"
    assert test_goal['current_value'].to_f > 0, "Current value should be calculated"
    assert test_goal['progress_percentage'].to_f > 0, "Progress should be calculated"
    
    puts "✅ Meta Individual - Current: R$ #{test_goal['current_value']}, Progress: #{test_goal['progress_percentage']}%"
  end

  test "should calculate progress correctly for store wide goal" do
    # Criar meta por loja para período com vendas conhecidas
    goal = Goal.create!(
      seller_id: nil,
      store_id: @store.id,
      goal_type: 'sales',
      goal_scope: 'store_wide',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 200000,
      description: 'Meta teste loja'
    )
    
    login_as(@store_user)
    get '/goals', headers: @headers, as: :json
    assert_response :success
    
    # Verificar se o progresso foi calculado
    response_data = JSON.parse(response.body)
    test_goal = response_data.find { |g| g['id'] == goal.id }
    
    assert_not_nil test_goal, "Goal should be found in response"
    assert test_goal['current_value'].to_f > 0, "Current value should be calculated"
    assert test_goal['progress_percentage'].to_f > 0, "Progress should be calculated"
    
    puts "✅ Meta Loja - Current: R$ #{test_goal['current_value']}, Progress: #{test_goal['progress_percentage']}%"
  end

  test "should recalculate progress manually" do
    # Criar meta para o seller da loja correta
    goal = Goal.create!(
      seller_id: @seller.id,
      store_id: @store.id,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 30000,
      current_value: 0  # Começar com 0
    )
    
    login_as(@store_user)
    post "/goals/#{goal.id}/recalculate_progress", headers: @headers, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert response_data['current_value'].to_f > 0, "Should recalculate current value"
    assert response_data['progress_percentage'].to_f > 0, "Should recalculate progress"
    
    puts "✅ Recálculo Manual - Current: R$ #{response_data['current_value']}, Progress: #{response_data['progress_percentage']}%"
  end

  # === TESTES DE AUTORIZAÇÃO ===
  
  test "store user can only see own store goals" do
    login_as(@store_user)
    get '/goals', headers: @headers, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    # Verificar se apenas metas da loja aparecem
    response_data.each do |goal|
      if goal['seller_id']
        seller = Seller.find(goal['seller_id'])
        assert_equal @store.id, seller.store_id, "Individual goal should belong to user's store"
      else
        assert_equal 'store_wide', goal['goal_scope'], "Store-wide goal should be included"
      end
    end
    
    puts "✅ Autorização - Usuário vê apenas metas da própria loja"
  end

  test "can delete store wide goal" do
    goal = Goal.create!(
      seller_id: nil,
      store_id: @store.id,
      goal_type: 'sales',
      goal_scope: 'store_wide',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 100000
    )
    
    login_as(@store_user)
    delete "/goals/#{goal.id}", headers: @headers, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal 'Meta excluída com sucesso', response_data['message']
    
    puts "✅ Exclusão - Meta por loja excluída com sucesso"
  end

  test "can update store wide goal" do
    goal = Goal.create!(
      seller_id: nil,
      store_id: @store.id,
      goal_type: 'sales',
      goal_scope: 'store_wide',
      start_date: '2025-08-01',
      end_date: '2025-08-31',
      target_value: 100000
    )
    
    login_as(@store_user)
    put "/goals/#{goal.id}", params: {
      goal: {
        target_value: 150000,
        description: 'Meta atualizada'
      }
    }, headers: @headers, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "150000.0", response_data['target_value'], "Target value should be returned as formatted string"
    
    puts "✅ Atualização - Meta por loja atualizada com sucesso"
  end

  private

  def login_as(user)
    # Simular autenticação usando headers de autorização
    @token = generate_jwt_token(user)
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end

  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
  end

  def create_test_orders
    # Criar alguns pedidos com vendas para testar cálculo
    return unless @seller && @store
    
    # Criar um produto de teste se não existir
    product = Product.find_or_create_by!(
      external_id: 'TEST_PRODUCT',
      name: 'Produto Teste',
      sku: 'SKU_TEST',
      category: categories(:one)
    )
    
    # Ordem 1 - Agosto 2025
    order1 = Order.create!(
      seller: @seller,
      store: @store,
      external_id: 'TEST001',
      sold_at: '2025-08-10'
    )
    
    OrderItem.create!(
      order: order1,
      product: product,
      external_id: 'ITEM001',
      quantity: 2,
      unit_price: 15000,
      store: @store
    )
    
    # Ordem 2 - Agosto 2025  
    order2 = Order.create!(
      seller: @seller,
      store: @store,
      external_id: 'TEST002',
      sold_at: '2025-08-15'
    )
    
    OrderItem.create!(
      order: order2,
      product: product,
      external_id: 'ITEM002',
      quantity: 1,
      unit_price: 25000,
      store: @store
    )
    
    puts "📦 Criados pedidos de teste: R$ 55.000 total em agosto"
  end
end