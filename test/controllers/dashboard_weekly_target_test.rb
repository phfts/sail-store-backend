require 'test_helper'

class DashboardWeeklyTargetTest < ActionDispatch::IntegrationTest
  def setup
    @store = stores(:souq_iguatemi)
    @controller = DashboardController.new
  end

  test "calculate_weekly_target when target already reached" do
    # Simular: meta mensal de R$ 5.000, vendas atuais de R$ 6.000 (já bateu a meta)
    current_month_sales = 6000.0
    current_target = 5000.0
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    assert_equal 0, result
  end

  test "calculate_weekly_target with zero target" do
    # Simular: sem meta definida
    current_month_sales = 1000.0
    current_target = 0.0
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    assert_equal 0, result
  end

  test "calculate_weekly_target with exact target match" do
    # Simular: vendas exatamente iguais à meta
    current_month_sales = 10000.0
    current_target = 10000.0
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    assert_equal 0, result
  end

  test "weekly_target_never_exceeds_remaining_target" do
    # Teste crítico: verificar que a meta semanal nunca excede o valor restante
    current_month_sales = 8000.0
    current_target = 10000.0
    remaining_target = current_target - current_month_sales # R$ 2.000
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    
    # A meta semanal NUNCA pode ser maior que o valor restante
    assert result <= remaining_target, "Meta semanal (#{result}) não pode ser maior que o valor restante (#{remaining_target})"
    assert result > 0, "Meta semanal deve ser maior que 0 quando há valor restante"
  end

  test "weekly_target_calculation_logic" do
    # Teste para verificar a lógica do cálculo
    current_month_sales = 5000.0
    current_target = 10000.0
    remaining_target = current_target - current_month_sales # R$ 5.000
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    
    # Verificar que o resultado é lógico
    assert result > 0, "Meta semanal deve ser maior que 0"
    assert result <= remaining_target, "Meta semanal não pode exceder o valor restante"
    
    # Verificar que é proporcional aos dias da semana
    # A meta semanal deve ser menor ou igual ao valor restante
    assert result <= remaining_target, "Meta semanal deve ser menor ou igual ao valor restante"
  end

  test "weekly_target_with_large_remaining_amount" do
    # Simular: ainda falta muito para bater a meta
    current_month_sales = 1000.0
    current_target = 50000.0
    remaining_target = current_target - current_month_sales # R$ 49.000
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    
    # Deve retornar um valor positivo
    assert result > 0, "Meta semanal deve ser maior que 0"
    # Deve ser menor ou igual ao valor restante
    assert result <= remaining_target, "Meta semanal não pode exceder o valor restante"
  end

  test "weekly_target_with_small_remaining_amount" do
    # Simular: falta pouco para bater a meta
    current_month_sales = 9500.0
    current_target = 10000.0
    remaining_target = current_target - current_month_sales # R$ 500
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    
    # Deve retornar um valor positivo
    assert result > 0, "Meta semanal deve ser maior que 0"
    # Deve ser menor ou igual ao valor restante
    assert result <= remaining_target, "Meta semanal não pode exceder o valor restante"
  end

  test "weekly_target_edge_case_zero_sales" do
    # Simular: nenhuma venda ainda
    current_month_sales = 0.0
    current_target = 10000.0
    remaining_target = current_target - current_month_sales # R$ 10.000
    
    result = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    
    # Deve retornar um valor positivo
    assert result > 0, "Meta semanal deve ser maior que 0"
    # Deve ser menor ou igual ao valor restante
    assert result <= remaining_target, "Meta semanal não pode exceder o valor restante"
  end
end
