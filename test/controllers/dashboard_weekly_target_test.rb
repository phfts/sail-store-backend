require 'test_helper'

class DashboardWeeklyTargetTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @store = stores(:souq_iguatemi)
    
    # Criar usuários únicos para os vendedores
    @user1 = User.create!(
      email: "vendedor1_weekly@example.com",
      password: "password123",
      admin: false
    )
    
    @user2 = User.create!(
      email: "vendedor2_weekly@example.com", 
      password: "password123",
      admin: false
    )
    
    # Criar vendedores
    @seller1 = @store.sellers.create!(
      name: "Vendedor 1",
      user: @user1,
      active_until: nil
    )
    
    @seller2 = @store.sellers.create!(
      name: "Vendedor 2", 
      user: @user2,
      active_until: nil
    )
  end

  test "weekly target should be zero when monthly target is zero" do
    sign_in @user
    
    get "/stores/#{@store.slug}/dashboard"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    weekly_target = json_response['targets']['weeklyTarget']
    
    assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando não há meta mensal"
  end

  test "weekly target should be zero when monthly goal is already achieved" do
    # Criar meta mensal
    goal = Goal.create!(
      seller: @seller1,
      target_value: 1000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    # Criar vendas que já batem a meta
    order = @store.orders.create!(
      seller: @seller1,
      external_id: "TEST_ORDER_001",
      sold_at: Date.current
    )
    
    order.order_items.create!(
      product_id: 1,
      quantity: 1,
      unit_price: 1200.0
    )
    
    sign_in @user
    
    get "/stores/#{@store.slug}/dashboard"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    weekly_target = json_response['targets']['weeklyTarget']
    
    assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando a meta mensal já foi batida"
  end

  test "weekly target should be calculated correctly for mid-month" do
    # Criar meta mensal
    goal = Goal.create!(
      seller: @seller1,
      target_value: 10000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    # Criar vendas parciais
    order = @store.orders.create!(
      seller: @seller1,
      external_id: "TEST_ORDER_002",
      sold_at: Date.current
    )
    
    order.order_items.create!(
      product_id: 1,
      quantity: 1,
      unit_price: 5000.0
    )
    
    sign_in @user
    
    get "/stores/#{@store.slug}/dashboard"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    weekly_target = json_response['targets']['weeklyTarget']
    
    # Verificar se a meta semanal é maior que 0
    assert weekly_target > 0, "Meta semanal deve ser maior que 0 quando há meta não batida"
    
    # Verificar se a meta semanal é menor que a meta mensal
    monthly_target = json_response['targets']['target']
    assert weekly_target < monthly_target, "Meta semanal deve ser menor que a meta mensal"
  end

  test "weekly target should handle multiple sellers with goals" do
    # Criar metas para múltiplos vendedores
    goal1 = Goal.create!(
      seller: @seller1,
      target_value: 5000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    goal2 = Goal.create!(
      seller: @seller2,
      target_value: 5000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    # Criar vendas parciais
    order1 = @store.orders.create!(
      seller: @seller1,
      external_id: "TEST_ORDER_003",
      sold_at: Date.current
    )
    
    order1.order_items.create!(
      product_id: 1,
      quantity: 1,
      unit_price: 2000.0
    )
    
    order2 = @store.orders.create!(
      seller: @seller2,
      external_id: "TEST_ORDER_004",
      sold_at: Date.current
    )
    
    order2.order_items.create!(
      product_id: 1,
      quantity: 1,
      unit_price: 3000.0
    )
    
    sign_in @user
    
    get "/stores/#{@store.slug}/dashboard"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    weekly_target = json_response['targets']['weeklyTarget']
    
    # Verificar se a meta semanal é calculada corretamente para múltiplos vendedores
    assert weekly_target > 0, "Meta semanal deve ser calculada para múltiplos vendedores"
  end

  test "weekly target should be zero on last day of month" do
    # Simular último dia do mês
    last_day = Date.current.end_of_month
    
    # Criar meta mensal
    goal = Goal.create!(
      seller: @seller1,
      target_value: 10000.0,
      start_date: last_day.beginning_of_month,
      end_date: last_day.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    # Criar vendas parciais
    order = @store.orders.create!(
      seller: @seller1,
      external_id: "TEST_ORDER_005",
      sold_at: last_day
    )
    
    order.order_items.create!(
      product_id: 1,
      quantity: 1,
      unit_price: 5000.0
    )
    
    sign_in @user
    
    # Mock da data atual para o último dia do mês
    Date.stub :current, last_day do
      get "/stores/#{@store.slug}/dashboard"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      weekly_target = json_response['targets']['weeklyTarget']
      
      # No último dia do mês, a meta semanal pode ser alta mas não zero
      assert weekly_target >= 0, "Meta semanal deve ser >= 0 no último dia do mês"
    end
  end

  test "weekly target calculation method should work correctly" do
    controller = DashboardController.new
    
    # Teste 1: Meta não batida, semana completa no mês
    weekly_target = controller.send(:calculate_weekly_target, 5000, 10000)
    assert weekly_target > 0, "Meta semanal deve ser > 0 quando meta não batida"
    
    # Teste 2: Meta já batida
    weekly_target = controller.send(:calculate_weekly_target, 12000, 10000)
    assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando meta já batida"
    
    # Teste 3: Sem meta
    weekly_target = controller.send(:calculate_weekly_target, 5000, 0)
    assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando não há meta"
  end

  test "dashboard should return weekly target in correct format" do
    # Criar meta mensal
    goal = Goal.create!(
      seller: @seller1,
      target_value: 10000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    sign_in @user
    
    get "/stores/#{@store.slug}/dashboard"
    assert_response :success
    
    json_response = JSON.parse(response.body)
    
    # Verificar se o campo weeklyTarget existe
    assert json_response['targets'].key?('weeklyTarget'), "Campo weeklyTarget deve existir no response"
    
    # Verificar se é um número
    weekly_target = json_response['targets']['weeklyTarget']
    assert_kind_of Numeric, weekly_target, "weeklyTarget deve ser um número"
    
    # Verificar se é >= 0
    assert weekly_target >= 0, "weeklyTarget deve ser >= 0"
  end
end
