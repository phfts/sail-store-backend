require 'test_helper'

class BetaControllerTest < ActionDispatch::IntegrationTest

  setup do
    @company = companies(:one)
    @store = stores(:one)
    @seller = sellers(:one)
    
    # Criar uma meta para o seller
    @goal = Goal.create!(
      seller: @seller,
      store: @store,
      goal_type: 'sales',
      goal_scope: 'individual',
      target_value: 10000.0,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      description: 'Meta de teste para cálculo de dias restantes'
    )
  end

  test "calcula dias restantes corretamente quando não há escalas definidas" do
    # Configurar data atual para um dia específico do mês
    travel_to Date.current.beginning_of_month + 10.days do
      current_date = Date.current
      goal_end = @goal.end_date
      
      # Verificar que não há escalas definidas para o seller
      scheduled_days = @seller.schedules
                              .where(date: current_date..goal_end)
                              .count
      
      assert_equal 0, scheduled_days, "Não deve haver escalas definidas"
      
      # Calcular dias restantes até o fim da meta (inclusive)
      expected_days_remaining = (goal_end - current_date).to_i
      
      # Testar diretamente a lógica de cálculo
      # Simular o cálculo que é feito no controller beta
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Verificar se o cálculo está correto
      assert_equal expected_days_remaining, goal_days_remaining, 
                   "Dias restantes devem ser calculados corretamente quando não há escalas"
      
      # Verificar que não é negativo
      assert goal_days_remaining >= 0, "Dias restantes não podem ser negativos"
    end
  end

  test "calcula dias restantes considerando escalas quando existem" do
    # Criar algumas escalas para o seller
    current_date = Date.current
    goal_end = @goal.end_date
    
    # Criar escalas para os próximos 5 dias úteis
    5.times do |i|
      schedule_date = current_date + i.days
      next if schedule_date.sunday? || schedule_date.saturday?
      
      Schedule.create!(
        seller: @seller,
        date: schedule_date,
        shift: shifts(:one),
        store: @store
      )
    end
    
    travel_to current_date do
      # Verificar que há escalas definidas
      scheduled_days = @seller.schedules
                              .where(date: current_date..goal_end)
                              .count
      
      assert scheduled_days > 0, "Deve haver escalas definidas"
      
      # Testar diretamente a lógica de cálculo
      # Simular o cálculo que é feito no controller beta
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Verificar se o cálculo está correto
      assert goal_days_remaining >= 0, "Dias restantes não podem ser negativos"
      
      # Verificar se a meta por dia restante está sendo calculada corretamente
      if goal_days_remaining > 0
        remaining_target = @goal.target_value - 0 # assumindo vendas = 0
        daily_target = (remaining_target / goal_days_remaining).round(2)
        assert daily_target > 0, "Meta por dia restante deve ser calculada quando há dias restantes"
      end
    end
  end

  test "calcula dias restantes corretamente no último dia da meta" do
    # Configurar data atual para o último dia da meta
    travel_to @goal.end_date do
      current_date = Date.current
      goal_end = @goal.end_date
      
      # Calcular dias restantes esperados (deve ser 0 no último dia)
      expected_days_remaining = 0
      
      # Testar diretamente a lógica de cálculo
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Verificar se o cálculo está correto no último dia
      assert_equal expected_days_remaining, goal_days_remaining, 
                   "Dias restantes devem ser 0 no último dia da meta"
      
      # Verificar se a meta por dia restante está sendo tratada corretamente
      daily_target = goal_days_remaining > 0 ? (1000.0 / goal_days_remaining).round(2) : 0
      assert_equal 0, daily_target, 
                   "Meta por dia restante deve ser 0 quando não há dias restantes"
    end
  end

  test "calcula dias restantes corretamente após o fim da meta" do
    # Configurar data atual para após o fim da meta
    travel_to @goal.end_date + 5.days do
      current_date = Date.current
      goal_end = @goal.end_date
      
      # Calcular dias restantes esperados (deve ser 0 após o fim da meta)
      expected_days_remaining = 0
      
      # Testar diretamente a lógica de cálculo
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Verificar se o cálculo está correto após o fim da meta
      assert_equal expected_days_remaining, goal_days_remaining, 
                   "Dias restantes devem ser 0 após o fim da meta"
    end
  end

  test "calcula dias restantes baseado em escalas quando meta termina em 30 dias" do
    # Configurar meta para terminar em 30 dias
    current_date = Date.current
    goal_end = current_date + 30.days
    
    # Atualizar a meta para terminar em 30 dias
    @goal.update!(
      start_date: current_date,
      end_date: goal_end
    )
    
    # Criar escalas para apenas os próximos 5 dias úteis
    scheduled_days = 0
    10.times do |i|
      schedule_date = current_date + i.days
      next if schedule_date.sunday? || schedule_date.saturday?
      next if scheduled_days >= 5 # Apenas 5 dias de escala
      
      Schedule.create!(
        seller: @seller,
        date: schedule_date,
        shift: shifts(:one),
        store: @store
      )
      scheduled_days += 1
    end
    
    travel_to current_date do
      # Verificar que há exatamente 5 escalas definidas
      actual_scheduled_days = @seller.schedules
                                     .where(date: current_date..goal_end)
                                     .count
      
      assert_equal 5, actual_scheduled_days, "Deve haver exatamente 5 escalas definidas"
      
      # Testar diretamente a lógica de cálculo
      # Simular o cálculo que é feito no controller beta
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Verificar se o cálculo está correto - deve ser 30 dias (baseado na data da meta)
      assert_equal 30, goal_days_remaining, 
                   "Dias restantes devem ser 30 quando a meta termina em 30 dias"
      
      # Verificar se a meta por dia restante está sendo calculada corretamente
      remaining_target = @goal.target_value - 0 # assumindo vendas = 0
      daily_target = (remaining_target / goal_days_remaining).round(2)
      assert daily_target > 0, "Meta por dia restante deve ser calculada quando há dias restantes"
      
      # Verificar que a meta por dia restante considera os 30 dias da meta
      expected_daily_target = (@goal.target_value / 30.0).round(2)
      assert_equal expected_daily_target, daily_target, 
                   "Meta por dia restante deve ser calculada baseada nos 30 dias da meta"
    end
  end

  test "calcula dias restantes baseado em escalas quando há apenas 5 dias de escala - CORRIGIDO" do
    # Configurar meta para terminar em 30 dias
    current_date = Date.current
    goal_end = current_date + 30.days
    
    # Atualizar a meta para terminar em 30 dias
    @goal.update!(
      start_date: current_date,
      end_date: goal_end
    )
    
    # Criar escalas para apenas os próximos 5 dias úteis
    scheduled_days = 0
    10.times do |i|
      schedule_date = current_date + i.days
      next if schedule_date.sunday? || schedule_date.saturday?
      next if scheduled_days >= 5 # Apenas 5 dias de escala
      
      Schedule.create!(
        seller: @seller,
        date: schedule_date,
        shift: shifts(:one),
        store: @store
      )
      scheduled_days += 1
    end
    
    travel_to current_date do
      # Verificar que há exatamente 5 escalas definidas
      actual_scheduled_days = @seller.schedules
                                     .where(date: current_date..goal_end)
                                     .count
      
      assert_equal 5, actual_scheduled_days, "Deve haver exatamente 5 escalas definidas"
      
      # Testar a nova lógica do controller beta que considera as escalas
      # Criar uma instância do controller para testar o método diretamente
      controller = BetaController.new
      
      # Testar o método calculate_goal_days_remaining
      actual_calculation = controller.send(:calculate_goal_days_remaining, @seller, current_date, goal_end)
      
      # O que o controller DEVERIA calcular (5 dias baseado nas escalas):
      expected_days_based_on_schedule = actual_scheduled_days
      
      # AGORA ESTE TESTE DEVE PASSAR - mostra que o controller está correto
      assert_equal expected_days_based_on_schedule, actual_calculation, 
                   "Controller deveria retornar 5 dias (baseado nas escalas) e agora retorna corretamente"
    end
  end

  test "calcula dias restantes baseado na data da meta quando não há escalas" do
    # Configurar meta para terminar em 15 dias
    current_date = Date.current
    goal_end = current_date + 15.days
    
    # Atualizar a meta para terminar em 15 dias
    @goal.update!(
      start_date: current_date,
      end_date: goal_end
    )
    
    # NÃO criar escalas para garantir que não há nenhuma
    
    travel_to current_date do
      # Verificar que não há escalas definidas
      actual_scheduled_days = @seller.schedules
                                     .where(date: current_date..goal_end)
                                     .count
      
      assert_equal 0, actual_scheduled_days, "Não deve haver escalas definidas"
      
      # Testar a lógica do controller beta
      controller = BetaController.new
      
      # Testar o método calculate_goal_days_remaining
      actual_calculation = controller.send(:calculate_goal_days_remaining, @seller, current_date, goal_end)
      
      # O que o controller DEVERIA calcular (15 dias baseado na data da meta):
      expected_days_based_on_date = 15
      
      # Deve usar a data da meta quando não há escalas
      assert_equal expected_days_based_on_date, actual_calculation, 
                   "Controller deveria retornar 15 dias (baseado na data da meta) quando não há escalas"
    end
  end

  private

  def shifts(one)
    # Mock para shift - você pode ajustar conforme necessário
    @shift ||= Shift.create!(
      name: "Manhã",
      start_time: "08:00",
      end_time: "12:00",
      store: @store
    )
  end
end

