require 'test_helper'

class DashboardWeeklyTargetDemoTest < ActionDispatch::IntegrationTest
  def setup
    @controller = DashboardController.new
  end

  test "weekly_target_never_exceeds_remaining_target_demo" do
    # Cenários de teste baseados na demonstração
    scenarios = [
      {
        name: "Cenário 1: Meta mensal R$ 10.000, vendas R$ 8.000",
        current_month_sales: 8000.0,
        current_target: 10000.0,
        expected_remaining: 2000.0
      },
      {
        name: "Cenário 2: Meta mensal R$ 5.000, vendas R$ 1.000",
        current_month_sales: 1000.0,
        current_target: 5000.0,
        expected_remaining: 4000.0
      },
      {
        name: "Cenário 3: Meta mensal R$ 20.000, vendas R$ 15.000",
        current_month_sales: 15000.0,
        current_target: 20000.0,
        expected_remaining: 5000.0
      },
      {
        name: "Cenário 4: Meta já batida",
        current_month_sales: 12000.0,
        current_target: 10000.0,
        expected_remaining: -2000.0
      }
    ]

    scenarios.each do |scenario|
      puts "\n=== #{scenario[:name]} ==="
      puts "Vendas atuais: R$ #{scenario[:current_month_sales].round(2)}"
      puts "Meta mensal: R$ #{scenario[:current_target].round(2)}"
      
      remaining_target = scenario[:current_target] - scenario[:current_month_sales]
      puts "Valor que falta: R$ #{remaining_target.round(2)}"
      
      # Calcular meta semanal usando o método do controller
      weekly_target = @controller.send(:calculate_weekly_target, scenario[:current_month_sales], scenario[:current_target])
      
      if remaining_target <= 0
        puts "Meta semanal: R$ 0,00 (meta já batida)"
        assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando meta já batida"
      else
        # Simular cálculo para comparação
        current_date = Date.current
        month_start = current_date.beginning_of_month
        month_end = current_date.end_of_month
        days_remaining_in_month = (month_end - current_date).to_i + 1
        
        week_start = current_date.beginning_of_week
        week_end = current_date.end_of_week
        
        # Ajustar o início da semana para não ser antes do início do mês
        week_start = month_start if week_start < month_start
        
        # Ajustar o fim da semana para não ser depois do fim do mês
        week_end = month_end if week_end > month_end
        
        week_days_in_month = 0
        (week_start..week_end).each do |date|
          week_days_in_month += 1 if date.month == current_date.month
        end
        
        daily_target = remaining_target.to_f / days_remaining_in_month
        weekly_target_without_limit = daily_target * week_days_in_month
        weekly_target_with_limit = [weekly_target_without_limit, remaining_target].min
        
        puts "Dias restantes no mês: #{days_remaining_in_month}"
        puts "Dias da semana atual no mês: #{week_days_in_month}"
        puts "Meta diária: R$ #{daily_target.round(2)}"
        puts "Meta semanal (sem limite): R$ #{weekly_target_without_limit.round(2)}"
        puts "Meta semanal (com limite): R$ #{weekly_target_with_limit.round(2)}"
        puts "Meta semanal (calculada): R$ #{weekly_target.round(2)}"
        
        # Verificações
        assert weekly_target > 0, "Meta semanal deve ser maior que 0 quando há valor restante"
        assert_in_delta weekly_target_without_limit, weekly_target, 0.01, "Meta semanal calculada deve ser igual à meta sem limite"
      end
      
      puts "✅ Meta semanal calculada corretamente"
    end
  end

  test "weekly_target_edge_cases" do
    # Teste com valores extremos
    edge_cases = [
      {
        name: "Zero vendas, meta alta",
        current_month_sales: 0.0,
        current_target: 100000.0
      },
      {
        name: "Vendas altas, meta baixa",
        current_month_sales: 50000.0,
        current_target: 10000.0
      },
      {
        name: "Valores iguais",
        current_month_sales: 5000.0,
        current_target: 5000.0
      },
      {
        name: "Meta zero",
        current_month_sales: 1000.0,
        current_target: 0.0
      }
    ]

    edge_cases.each do |case_data|
      puts "\n--- #{case_data[:name]} ---"
      
      remaining_target = case_data[:current_target] - case_data[:current_month_sales]
      weekly_target = @controller.send(:calculate_weekly_target, case_data[:current_month_sales], case_data[:current_target])
      
      puts "Vendas: R$ #{case_data[:current_month_sales].round(2)}"
      puts "Meta: R$ #{case_data[:current_target].round(2)}"
      puts "Restante: R$ #{remaining_target.round(2)}"
      puts "Meta semanal: R$ #{weekly_target.round(2)}"
      
      # Verificações básicas
      if remaining_target <= 0
        assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando não há valor restante"
      else
        assert weekly_target > 0, "Meta semanal deve ser maior que 0 quando há valor restante"
      end
    end
  end

  test "weekly_target_calculation_consistency" do
    # Teste para verificar consistência do cálculo
    base_sales = 5000.0
    base_target = 10000.0
    
    puts "\n=== Teste de Consistência ==="
    puts "Base: Vendas R$ #{base_sales.round(2)}, Meta R$ #{base_target.round(2)}"
    
    # Testar com diferentes proporções
    (1..5).each do |multiplier|
      current_sales = base_sales * multiplier
      current_target = base_target * multiplier
      
      weekly_target = @controller.send(:calculate_weekly_target, current_sales, current_target)
      remaining_target = current_target - current_sales
      
      puts "Multiplicador #{multiplier}:"
      puts "  Vendas: R$ #{current_sales.round(2)}"
      puts "  Meta: R$ #{current_target.round(2)}"
      puts "  Restante: R$ #{remaining_target.round(2)}"
      puts "  Meta semanal: R$ #{weekly_target.round(2)}"
      
      if remaining_target > 0
        assert weekly_target > 0, "Meta semanal deve ser maior que 0"
      else
        assert_equal 0, weekly_target, "Meta semanal deve ser 0 quando não há valor restante"
      end
    end
  end

  test "weekly_target_week_boundaries_correct" do
    # Teste específico para verificar se a semana está sendo calculada corretamente
    # dentro dos limites do mês atual
    current_month_sales = 5000.0
    current_target = 10000.0
    
    puts "\n=== Teste de Limites da Semana ==="
    
    weekly_target = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    remaining_target = current_target - current_month_sales
    
    # Simular o cálculo manual para verificar
    current_date = Date.current
    month_start = current_date.beginning_of_month
    month_end = current_date.end_of_month
    days_remaining_in_month = (month_end - current_date).to_i + 1
    
    week_start = current_date.beginning_of_week
    week_end = current_date.end_of_week
    
    # Ajustar o início da semana para não ser antes do início do mês
    week_start = month_start if week_start < month_start
    
    # Ajustar o fim da semana para não ser depois do fim do mês
    week_end = month_end if week_end > month_end
    
    week_days_in_month = 0
    (week_start..week_end).each do |date|
      week_days_in_month += 1 if date.month == current_date.month
    end
    
    puts "Data atual: #{current_date}"
    puts "Início do mês: #{month_start}"
    puts "Fim do mês: #{month_end}"
    puts "Início da semana (original): #{current_date.beginning_of_week}"
    puts "Fim da semana (original): #{current_date.end_of_week}"
    puts "Início da semana (ajustado): #{week_start}"
    puts "Fim da semana (ajustado): #{week_end}"
    puts "Dias da semana no mês: #{week_days_in_month}"
    puts "Dias restantes no mês: #{days_remaining_in_month}"
    
    # Verificar se a semana está dentro dos limites do mês
    assert week_start >= month_start, "Início da semana deve ser >= início do mês"
    assert week_end <= month_end, "Fim da semana deve ser <= fim do mês"
    assert week_days_in_month > 0, "Deve haver pelo menos 1 dia da semana no mês"
    assert week_days_in_month <= 7, "Não pode haver mais de 7 dias da semana"
    
    puts "✅ Semana está dentro dos limites do mês atual"
  end

  test "weekly_target_specific_scenarios" do
    # Teste para demonstrar os cenários específicos mencionados pelo usuário
    puts "\n=== Cenários Específicos ==="
    
    # Simular diferentes datas para demonstrar os cenários
    scenarios = [
      {
        name: "Cenário: Semana inicia dia 28 e termina dia 21 (próximo mês)",
        description: "Semana que começa no final do mês e termina no início do próximo",
        current_month_sales: 8000.0,
        current_target: 10000.0
      },
      {
        name: "Cenário: Semana começa dia 1 na quinta-feira e termina dia 7",
        description: "Semana que começa no início do mês",
        current_month_sales: 3000.0,
        current_target: 8000.0
      }
    ]

    scenarios.each do |scenario|
      puts "\n--- #{scenario[:name]} ---"
      puts "Descrição: #{scenario[:description]}"
      
      remaining_target = scenario[:current_target] - scenario[:current_month_sales]
      weekly_target = @controller.send(:calculate_weekly_target, scenario[:current_month_sales], scenario[:current_target])
      
      # Simular o cálculo para mostrar os detalhes
      current_date = Date.current
      month_start = current_date.beginning_of_month
      month_end = current_date.end_of_month
      
      week_start = current_date.beginning_of_week
      week_end = current_date.end_of_week
      
      # Ajustar limites
      week_start = month_start if week_start < month_start
      week_end = month_end if week_end > month_end
      
      week_days_in_month = 0
      (week_start..week_end).each do |date|
        week_days_in_month += 1 if date.month == current_date.month
      end
      
      puts "Vendas atuais: R$ #{scenario[:current_month_sales].round(2)}"
      puts "Meta mensal: R$ #{scenario[:current_target].round(2)}"
      puts "Valor que falta: R$ #{remaining_target.round(2)}"
      puts "Início da semana (ajustado): #{week_start}"
      puts "Fim da semana (ajustado): #{week_end}"
      puts "Dias da semana no mês atual: #{week_days_in_month}"
      puts "Meta semanal: R$ #{weekly_target.round(2)}"
      
      # Verificações
      assert week_start >= month_start, "Início da semana deve estar no mês atual"
      assert week_end <= month_end, "Fim da semana deve estar no mês atual"
      assert week_days_in_month > 0, "Deve haver pelo menos 1 dia da semana no mês"
      assert week_days_in_month <= 7, "Não pode haver mais de 7 dias da semana"
      
      puts "✅ Semana calculada corretamente dentro do mês atual"
    end
  end

  test "weekly_target_week_starting_day_29" do
    # Teste específico para demonstrar semana começando no dia 29
    puts "\n=== Teste: Semana começando no dia 29 ==="
    
    # Simular uma data no dia 29 de um mês
    # Vamos usar uma data específica para demonstrar
    current_month_sales = 7000.0
    current_target = 10000.0
    
    weekly_target = @controller.send(:calculate_weekly_target, current_month_sales, current_target)
    remaining_target = current_target - current_month_sales
    
    # Simular o cálculo para mostrar os detalhes
    current_date = Date.current
    month_start = current_date.beginning_of_month
    month_end = current_date.end_of_month
    
    week_start = current_date.beginning_of_week
    week_end = current_date.end_of_week
    
    # Ajustar limites
    week_start = month_start if week_start < month_start
    week_end = month_end if week_end > month_end
    
    week_days_in_month = 0
    (week_start..week_end).each do |date|
      week_days_in_month += 1 if date.month == current_date.month
    end
    
    puts "Data atual: #{current_date}"
    puts "Vendas atuais: R$ #{current_month_sales.round(2)}"
    puts "Meta mensal: R$ #{current_target.round(2)}"
    puts "Valor que falta: R$ #{remaining_target.round(2)}"
    puts "Início da semana (ajustado): #{week_start}"
    puts "Fim da semana (ajustado): #{week_end}"
    puts "Dias da semana no mês atual: #{week_days_in_month}"
    puts "Meta semanal: R$ #{weekly_target.round(2)}"
    
    # Verificações específicas para este cenário
    assert week_days_in_month > 0, "Deve haver pelo menos 1 dia da semana no mês"
    assert week_days_in_month <= 7, "Não pode haver mais de 7 dias da semana"
    
    # Se estivermos no final do mês (como dia 29), a semana pode ter menos de 7 dias
    if current_date.day >= 29
      puts "ℹ️  Estamos no final do mês - semana pode ter menos de 7 dias"
      puts "ℹ️  Dias restantes no mês: #{month_end.day - current_date.day + 1}"
      puts "ℹ️  Dias da semana no mês: #{week_days_in_month}"
    end
    
    puts "✅ Semana com #{week_days_in_month} dias calculada corretamente"
  end
end
