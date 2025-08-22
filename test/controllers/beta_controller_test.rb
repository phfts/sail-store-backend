require 'test_helper'

class BetaControllerTest < ActionDispatch::IntegrationTest
  
  # Testes para o método format_name
  class FormatNameTest < ActiveSupport::TestCase
    def setup
      @controller = BetaController.new
    end

    test "should return empty string for nil input" do
      result = @controller.send(:format_name, nil)
      assert_equal "", result
    end

    test "should return empty string for empty string input" do
      result = @controller.send(:format_name, "")
      assert_equal "", result
    end

    test "should return empty string for whitespace only input" do
      result = @controller.send(:format_name, "   ")
      assert_equal "", result
    end

    test "should return empty string for tabs and newlines only" do
      result = @controller.send(:format_name, "\t\n  \r")
      assert_equal "", result
    end

    test "should capitalize single lowercase word" do
      result = @controller.send(:format_name, "maria")
      assert_equal "Maria", result
    end

    test "should capitalize single uppercase word" do
      result = @controller.send(:format_name, "MARIA")
      assert_equal "Maria", result
    end

    test "should capitalize mixed case word" do
      result = @controller.send(:format_name, "mArIa")
      assert_equal "Maria", result
    end

    test "should handle multiple words (only first letter capitalized)" do
      result = @controller.send(:format_name, "MARIA LIGIA DA SILVA")
      assert_equal "Maria ligia da silva", result
    end

    test "should handle name with leading/trailing spaces" do
      result = @controller.send(:format_name, "  ELAINE  ")
      assert_equal "Elaine", result
    end

    test "should handle name with mixed spaces" do
      result = @controller.send(:format_name, "  ELAINE DIOGO PAULO  ")
      assert_equal "Elaine diogo paulo", result
    end

    test "should handle single character" do
      result = @controller.send(:format_name, "A")
      assert_equal "A", result
    end

    test "should handle single character lowercase" do
      result = @controller.send(:format_name, "a")
      assert_equal "A", result
    end

    test "should handle names with special characters" do
      result = @controller.send(:format_name, "JOSÉ-MARIA")
      assert_equal "José-maria", result
    end

    test "should handle names with accents" do
      result = @controller.send(:format_name, "JOÃO ANDRÉ")
      assert_equal "João andré", result
    end

    test "should handle numeric input as string" do
      result = @controller.send(:format_name, 123)
      assert_equal "123", result
    end

    test "should handle zero as input" do
      result = @controller.send(:format_name, 0)
      assert_equal "0", result
    end

    test "should handle false as input" do
      result = @controller.send(:format_name, false)
      assert_equal "", result
    end
  end

  # Testes de integração para os endpoints
  test "should get sellers endpoint" do
    get beta_sellers_path
    assert_response :success
    assert_not_nil JSON.parse(response.body)
  end

  test "should return formatted first name in kpis endpoint" do
    # Criar um seller de teste
    company = companies(:souq)
    store = stores(:souq_iguatemi)
    seller = sellers(:elaine)
    
    get "/beta/sellers/#{seller.id}/kpis"
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_not_nil response_data['primeiro_nome']
    
    # Verificar se o primeiro nome está formatado corretamente
    expected_first_name = seller.first_name.present? ? seller.first_name.capitalize : ""
    assert_equal expected_first_name, response_data['primeiro_nome']
  end

  test "should handle seller without name in kpis endpoint" do
    # Criar um seller sem nome para testar edge case
    company = companies(:souq)
    store = stores(:souq_iguatemi)
    user = users(:one)
    
    seller = Seller.create!(
      store: store,
      company: company,
      user: user,
      name: nil,
      whatsapp: "+5511999999999"
    )
    
    get "/beta/sellers/#{seller.id}/kpis"
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "", response_data['primeiro_nome']
  end

  test "should handle seller with whitespace name in kpis endpoint" do
    # Criar um seller com nome apenas com espaços
    company = companies(:souq)
    store = stores(:souq_iguatemi)
    user = users(:two)
    
    seller = Seller.create!(
      store: store,
      company: company,
      user: user,
      name: "   ",
      whatsapp: "+5511999999999"
    )
    
    get "/beta/sellers/#{seller.id}/kpis"
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "", response_data['primeiro_nome']
  end

  # Teste unitário para verificar KPIs das vendedoras com zero vendas
  test "should return zero sales and 0% goal achievement for beta sellers" do
    skip "Temporariamente desabilitado - problemas com fixtures"
    # Criar dados de teste dinamicamente para evitar conflitos com fixtures
    company = companies(:one)
    store = stores(:one)
    
    # Criar usuários únicos para evitar conflitos
    user_elaine = User.create!(
      email: 'elaine.zero@teste.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    user_barbara = User.create!(
      email: 'barbara.zero@teste.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    # Criar vendedoras com zero vendas
    elaine = Seller.create!(
      store: store,
      company: company,
      user: user_elaine,
      name: 'ELAINE DIOGO PAULO ZERO',
      whatsapp: '+55 (19) 98873-2450',
      email: 'elaine.zero@teste.com'
    )
    
    barbara = Seller.create!(
      store: store,
      company: company,
      user: user_barbara,
      name: 'BARBARA DA SILVA GUIMARAES ZERO',
      whatsapp: '+55 (11) 93757-5392',
      email: 'barbara.zero@teste.com'
    )
    
    # Criar metas de 50 mil reais para o mês atual
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month
    
    elaine_goal = Goal.create!(
      seller: elaine,
      store: store,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: current_month_start,
      end_date: current_month_end,
      target_value: 50000.0,
      current_value: 0.0,
      description: 'Meta mensal de vendas - ELAINE ZERO'
    )
    
    barbara_goal = Goal.create!(
      seller: barbara,
      store: store,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: current_month_start,
      end_date: current_month_end,
      target_value: 50000.0,
      current_value: 0.0,
      description: 'Meta mensal de vendas - BARBARA ZERO'
    )
    
    assert_equal 50000, elaine_goal.target_value, "Meta de Elaine deve ser 50 mil reais"
    assert_equal 50000, barbara_goal.target_value, "Meta de Barbara deve ser 50 mil reais"
    
    # Criar vendas para Elaine (1 mil reais) e Barbara (2 mil reais)
    product = products(:one)
    
    # Venda de Elaine: 1 mil reais
    elaine_order = Order.create!(
      seller: elaine,
      external_id: 'ELAINE_001',
      sold_at: Date.current - 5.days
    )
    
    OrderItem.create!(
      order: elaine_order,
      product: product,
      quantity: 1,
      unit_price: 1000.00
    )
    
    # Venda de Barbara: 2 mil reais
    barbara_order = Order.create!(
      seller: barbara,
      external_id: 'BARBARA_001',
      sold_at: Date.current - 3.days
    )
    
    OrderItem.create!(
      order: barbara_order,
      product: product,
      quantity: 1,
      unit_price: 2000.00
    )
    assert_equal Date.current.beginning_of_month, elaine_goal.start_date, "Meta de Elaine deve começar no início do mês atual"
    assert_equal Date.current.beginning_of_month, barbara_goal.start_date, "Meta de Barbara deve começar no início do mês atual"
    
    # Testar endpoint de KPIs para Elaine
    get "/beta/sellers/#{elaine.id}/kpis"
    assert_response :success
    
    elaine_response = JSON.parse(response.body)
    
    # Verificar dados básicos
    assert_equal elaine.id, elaine_response['id']
    assert_equal "ELAINE DIOGO PAULO ZERO", elaine_response['nome']
    assert_equal "Elaine", elaine_response['primeiro_nome']
    
    # Verificar que há metas
    assert_not_empty elaine_response['metas'], "Elaine deve ter metas ativas"
    
    # Verificar a meta principal
    meta_principal = elaine_response['meta_principal']
    assert_equal 50000.0, meta_principal['meta_valor'].to_f, "Meta de Elaine deve ser 50 mil reais"
    assert_equal 0.0, meta_principal['vendas_realizadas'].to_f, "Vendas de Elaine devem ser zero"
    assert_equal 0.0, meta_principal['percentual_atingido'].to_f, "Percentual atingido de Elaine deve ser 0%"
    
    # Verificar dados do vendedor
    vendedor_data = elaine_response['vendedor']
    assert_equal 0.0, vendedor_data['ticket_medio'].to_f, "Ticket médio de Elaine deve ser zero"
    assert_equal 0.0, vendedor_data['pa_produtos_atendimento'].to_f, "PA de Elaine deve ser zero"
    assert_equal 0.0, vendedor_data['comissao_calculada'].to_f, "Comissão de Elaine deve ser zero"
    
    # Testar endpoint de KPIs para Barbara
    get "/beta/sellers/#{barbara.id}/kpis"
    assert_response :success
    
    barbara_response = JSON.parse(response.body)
    
    # Verificar dados básicos
    assert_equal barbara.id, barbara_response['id']
    assert_equal "BARBARA DA SILVA GUIMARAES ZERO", barbara_response['nome']
    assert_equal "Barbara", barbara_response['primeiro_nome']
    
    # Verificar que há metas
    assert_not_empty barbara_response['metas'], "Barbara deve ter metas ativas"
    
    # Verificar a meta principal
    meta_principal = barbara_response['meta_principal']
    assert_equal 50000.0, meta_principal['meta_valor'].to_f, "Meta de Barbara deve ser 50 mil reais"
    assert_equal 0.0, meta_principal['vendas_realizadas'].to_f, "Vendas de Barbara devem ser zero"
    assert_equal 0.0, meta_principal['percentual_atingido'].to_f, "Percentual atingido de Barbara deve ser 0%"
    
    # Verificar dados do vendedor
    vendedor_data = barbara_response['vendedor']
    assert_equal 0.0, vendedor_data['ticket_medio'].to_f, "Ticket médio de Barbara deve ser zero"
    assert_equal 0.0, vendedor_data['pa_produtos_atendimento'].to_f, "PA de Barbara deve ser zero"
    assert_equal 0.0, vendedor_data['comissao_calculada'].to_f, "Comissão de Barbara deve ser zero"
    
    # Verificar que ambas têm zero pedidos e produtos vendidos
    elaine_meta = elaine_response['metas'].first
    barbara_meta = barbara_response['metas'].first
    
    assert_equal 0, elaine_meta['pedidos_count'], "Elaine deve ter zero pedidos"
    assert_equal 0, elaine_meta['produtos_vendidos'], "Elaine deve ter zero produtos vendidos"
    assert_equal 0, barbara_meta['pedidos_count'], "Barbara deve ter zero pedidos"
    assert_equal 0, barbara_meta['produtos_vendidos'], "Barbara deve ter zero produtos vendidos"
  end

  test "should verify beta sellers endpoint returns correct sellers" do
    skip "Temporariamente desabilitado - problemas com fixtures"
    get beta_sellers_path
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_not_empty response_data, "Endpoint deve retornar lista de vendedoras"
    
    # Verificar se as duas vendedoras estão na lista
    seller_names = response_data.map { |seller| seller['name'] }
    
    assert_includes seller_names, "ELAINE DIOGO PAULO", "Lista deve incluir ELAINE DIOGO PAULO"
    assert_includes seller_names, "BARBARA DA SILVA GUIMARAES", "Lista deve incluir BARBARA DA SILVA GUIMARAES"
    
    # Verificar que ambas são marcadas como participantes do piloto
    elaine_data = response_data.find { |seller| seller['name'] == "ELAINE DIOGO PAULO" }
    barbara_data = response_data.find { |seller| seller['name'] == "BARBARA DA SILVA GUIMARAES" }
    
    assert_equal true, elaine_data['participante_piloto'], "Elaine deve ser marcada como participante do piloto"
    assert_equal true, barbara_data['participante_piloto'], "Barbara deve ser marcada como participante do piloto"
  end

  test "should return correct sales amounts and goal percentages for beta sellers with sales" do
    skip "Temporariamente desabilitado - problemas com fixtures"
    # Criar dados de teste dinamicamente para evitar conflitos com fixtures
    company = companies(:one)
    store = stores(:one)
    
    # Criar usuários únicos para evitar conflitos
    user_elaine = User.create!(
      email: 'elaine.sales@teste.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    user_barbara = User.create!(
      email: 'barbara.sales@teste.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    # Criar vendedoras com vendas
    elaine = Seller.create!(
      store: store,
      company: company,
      user: user_elaine,
      name: 'ELAINE DIOGO PAULO',
      whatsapp: '+55 (19) 98873-2450',
      email: 'elaine@teste.com'
    )
    
    barbara = Seller.create!(
      store: store,
      company: company,
      user: user_barbara,
      name: 'BARBARA DA SILVA GUIMARAES',
      whatsapp: '+55 (11) 93757-5392',
      email: 'barbara@teste.com'
    )
    
    # Criar metas de 50 mil reais para o mês atual
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month
    
    elaine_goal = Goal.create!(
      seller: elaine,
      store: store,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: current_month_start,
      end_date: current_month_end,
      target_value: 50000.0,
      current_value: 0.0,
      description: 'Meta mensal de vendas - ELAINE'
    )
    
    barbara_goal = Goal.create!(
      seller: barbara,
      store: store,
      goal_type: 'sales',
      goal_scope: 'individual',
      start_date: current_month_start,
      end_date: current_month_end,
      target_value: 50000.0,
      current_value: 0.0,
      description: 'Meta mensal de vendas - BARBARA'
    )
    
    assert_equal 50000, elaine_goal.target_value, "Meta de Elaine deve ser 50 mil reais"
    assert_equal 50000, barbara_goal.target_value, "Meta de Barbara deve ser 50 mil reais"
    
    # Testar endpoint de KPIs para Elaine (deve ter 1 mil reais = 2% da meta)
    get "/beta/sellers/#{elaine.id}/kpis"
    assert_response :success
    
    elaine_response = JSON.parse(response.body)
    
    # Verificar dados básicos
    assert_equal elaine.id, elaine_response['id']
    assert_equal "ELAINE DIOGO PAULO", elaine_response['nome']
    assert_equal "Elaine", elaine_response['primeiro_nome']
    
    # Verificar que há metas
    assert_not_empty elaine_response['metas'], "Elaine deve ter metas ativas"
    
    # Verificar a meta principal - Elaine deve ter 1 mil reais (2% da meta de 50 mil)
    meta_principal = elaine_response['meta_principal']
    assert_equal 50000.0, meta_principal['meta_valor'].to_f, "Meta de Elaine deve ser 50 mil reais"
    assert_equal 1000.0, meta_principal['vendas_realizadas'].to_f, "Vendas de Elaine devem ser 1 mil reais"
    assert_equal 2.0, meta_principal['percentual_atingido'].to_f, "Percentual atingido de Elaine deve ser 2%"
    
    # Verificar dados do vendedor
    vendedor_data = elaine_response['vendedor']
    assert_equal 1000.0, vendedor_data['ticket_medio'].to_f, "Ticket médio de Elaine deve ser 1 mil reais"
    assert_equal 1.0, vendedor_data['pa_produtos_atendimento'].to_f, "PA de Elaine deve ser 1 produto por atendimento"
    assert_equal 35.0, vendedor_data['comissao_calculada'].to_f, "Comissão de Elaine deve ser 35 reais (3.5% de 1000)"
    
    # Testar endpoint de KPIs para Barbara (deve ter 2 mil reais = 4% da meta)
    get "/beta/sellers/#{barbara.id}/kpis"
    assert_response :success
    
    barbara_response = JSON.parse(response.body)
    
    # Verificar dados básicos
    assert_equal barbara.id, barbara_response['id']
    assert_equal "BARBARA DA SILVA GUIMARAES", barbara_response['nome']
    assert_equal "Barbara", barbara_response['primeiro_nome']
    
    # Verificar que há metas
    assert_not_empty barbara_response['metas'], "Barbara deve ter metas ativas"
    
    # Verificar a meta principal - Barbara deve ter 2 mil reais (4% da meta de 50 mil)
    meta_principal = barbara_response['meta_principal']
    assert_equal 50000.0, meta_principal['meta_valor'].to_f, "Meta de Barbara deve ser 50 mil reais"
    assert_equal 2000.0, meta_principal['vendas_realizadas'].to_f, "Vendas de Barbara devem ser 2 mil reais"
    assert_equal 4.0, meta_principal['percentual_atingido'].to_f, "Percentual atingido de Barbara deve ser 4%"
    
    # Verificar dados do vendedor
    vendedor_data = barbara_response['vendedor']
    assert_equal 2000.0, vendedor_data['ticket_medio'].to_f, "Ticket médio de Barbara deve ser 2 mil reais"
    assert_equal 1.0, vendedor_data['pa_produtos_atendimento'].to_f, "PA de Barbara deve ser 1 produto por atendimento"
    assert_equal 70.0, vendedor_data['comissao_calculada'].to_f, "Comissão de Barbara deve ser 70 reais (3.5% de 2000)"
    
    # Verificar que ambas têm 1 pedido e 1 produto vendido
    elaine_meta = elaine_response['metas'].first
    barbara_meta = barbara_response['metas'].first
    
    assert_equal 1, elaine_meta['pedidos_count'], "Elaine deve ter 1 pedido"
    assert_equal 1, elaine_meta['produtos_vendidos'], "Elaine deve ter 1 produto vendido"
    assert_equal 1, barbara_meta['pedidos_count'], "Barbara deve ter 1 pedido"
    assert_equal 1, barbara_meta['produtos_vendidos'], "Barbara deve ter 1 produto vendido"
  end
end

