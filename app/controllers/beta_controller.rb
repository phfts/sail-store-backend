class BetaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:sellers, :kpis, :managers, :manager_kpis]

  # GET /beta/sellers
  def sellers
    # Buscar beta_seller pelo nome (vendedora em beta)
    beta_seller =  Seller.includes(:store, :company).find_by_name('PALOMA COSTA MAIA')
    beta_seller_2 =  Seller.includes(:store, :company).find_by_name('LAIS FARIAS DOS SANTOS')

    if beta_seller
      # Retornar array com o ID real da beta_seller incluindo dados da loja
      render json: [
        {
          id: beta_seller.id, 
          name: beta_seller.name, 
          telefone: beta_seller.formatted_whatsapp || '+55 (19) 98873-2450',
          participante_piloto: true,
          store: {
            id: beta_seller.store.id,
            name: beta_seller.store.name,
            slug: beta_seller.store.slug,
            cnpj: beta_seller.store.cnpj,
            address: beta_seller.store.address
          },
          company: {
            id: beta_seller.company.id,
            name: beta_seller.company.name
          }
        }, 
        {
          id: beta_seller_2.id, 
          name: beta_seller_2.name, 
          telefone: beta_seller_2.formatted_whatsapp || '+55 (11) 93757-5392',
          participante_piloto: true,
          store: {
            id: beta_seller_2.store.id,
            name: beta_seller_2.store.name,
            slug: beta_seller_2.store.slug,
            cnpj: beta_seller_2.store.cnpj,
            address: beta_seller_2.store.address
          },
          company: {
            id: beta_seller_2.company.id,
            name: beta_seller_2.company.name
          }
        }
      ]
    else
      # Fallback caso não encontre - retornar array vazio ou ID mockado
      render json: []
    end
  end

  # GET /beta/managers
  def managers
    # Buscar todos os sellers que são admins das lojas
    store_managers = Seller.includes(:store, :company, :user)
                          .where(store_admin: true)
                          .order(:name)

    managers_data = store_managers.map do |manager|
      {
        id: manager.id,
        name: manager.display_name,
        email: manager.email,
        telefone: manager.formatted_whatsapp || '+55 (19) 98873-2450',
        store: {
          id: manager.store.id,
          name: manager.store.name,
          slug: manager.store.slug
        },
        company: {
          id: manager.company.id,
          name: manager.company.name
        },
        user_id: manager.user_id,
        external_id: manager.external_id,
        active: manager.active?,
        store_admin: manager.store_admin?
      }
    end

    render json: managers_data
  end

  # GET /beta/managers/:id/kpis
  def manager_kpis
    manager_id = params[:id]
    
    # Buscar manager pelo ID
    manager = Seller.includes(:store, :company, :user)
                   .where(store_admin: true)
                   .find_by(id: manager_id)
    
    if manager.nil?
      render json: { error: "Manager não encontrado" }, status: :not_found
      return
    end
    
    store = manager.store
    current_date = Date.current
    
    # Buscar todos os sellers ativos da loja
    store_sellers = store.sellers.includes(:goals, :orders => :order_items)
                        .where(active_until: nil)
                        .or(store.sellers.where('active_until > ?', current_date))
    
    # Buscar todas as metas ativas dos sellers da loja
    store_goals = Goal.joins(:seller)
                     .where(sellers: { store_id: store.id })
                     .active
                     .order(:start_date)
    
    # Processar cada meta da loja
    store_goals_data = []
    
    store_goals.each do |goal|
      goal_start = goal.start_date
      goal_end = goal.end_date
      goal_target = goal.target_value
      
      # Calcular vendas da loja no período da meta
      store_orders = Order.joins(:seller)
                         .where(sellers: { store_id: store.id })
                         .includes(:order_items)
                         .where('orders.sold_at >= ? AND orders.sold_at <= ?', goal_start, goal_end)
      
      store_sales = store_orders.joins(:order_items)
                               .sum('order_items.quantity * order_items.unit_price')
      
      # Calcular métricas do período
      store_orders_count = store_orders.count
      store_total_items = store_orders.joins(:order_items).sum('order_items.quantity')
      
      # Dias da meta
      goal_total_days = (goal_end - goal_start).to_i + 1
      goal_days_elapsed = [current_date - goal_start + 1, 0].max.to_i
      goal_days_remaining = calculate_goal_days_remaining(goal.seller, current_date, goal_end)
      
      # Calcular percentual e métricas
      goal_percentage = goal_target > 0 ? (store_sales / goal_target * 100).round(2) : 0
      goal_ticket = store_orders_count > 0 ? store_sales / store_orders_count : 0
      goal_pa = store_orders_count > 0 ? store_total_items.to_f / store_orders_count : 0
      
      # Calcular meta por dia restante
      remaining_target = [goal_target - store_sales, 0].max
      daily_target = goal_days_remaining > 0 ? (remaining_target / goal_days_remaining).round(2) : 0
      
      # Classificar tipo de período
      goal_type = case goal_total_days
                  when 1..7 then 'diario'
                  when 8..14 then 'semanal'
                  when 15..35 then 'mensal'
                  when 36..100 then 'trimestral'
                  else 'personalizado'
                  end
      
      store_goals_data << {
        id: goal.id,
        seller_id: goal.seller_id,
        seller_name: goal.seller.display_name,
        tipo: goal_type,
        nome_periodo: "#{goal_type.capitalize} (#{goal_total_days} dias)",
        inicio: goal_start.strftime("%d/%m/%Y"),
        fim: goal_end.strftime("%d/%m/%Y"),
        meta_valor: goal_target,
        vendas_realizadas: store_sales,
        percentual_atingido: goal_percentage,
        dias_total: goal_total_days,
        dias_decorridos: goal_days_elapsed,
        dias_restantes: goal_days_remaining,
        meta_por_dia_restante: daily_target,
        quanto_falta_super_meta: [(goal_target * 1.2) - store_sales, 0].max.round(2),
        ticket_medio: goal_ticket.round(2),
        pa_produtos_atendimento: goal_pa.round(1),
        pedidos_count: store_orders_count,
        produtos_vendidos: store_total_items,
        meta_data: {
          inicio_iso: goal_start.iso8601,
          fim_iso: goal_end.iso8601,
          goal_type: goal.goal_type,
          goal_scope: goal.goal_scope
        }
      }
    end
    
    # Se não há metas, calcular dados reais da loja para o mês atual
    if store_goals_data.empty?
      fallback_start = current_date.beginning_of_month
      fallback_end = current_date.end_of_month
      
      # Calcular vendas reais da loja no mês atual
      store_orders_month = Order.joins(:seller)
                               .where(sellers: { store_id: store.id })
                               .includes(:order_items)
                               .where('orders.sold_at >= ? AND orders.sold_at <= ?', fallback_start, [current_date, fallback_end].min)
      
      fallback_sales = store_orders_month.joins(:order_items).sum('order_items.quantity * order_items.unit_price')
      
      # Calcular meta baseada na média histórica da loja (últimos 3 meses)
      historical_orders = Order.joins(:seller)
                              .where(sellers: { store_id: store.id })
                              .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                    3.months.ago.beginning_of_month, 1.month.ago.end_of_month)
      
      historical_sales = historical_orders.joins(:order_items).sum('order_items.quantity * order_items.unit_price')
      historical_months = 3
      average_monthly_sales = historical_months > 0 ? historical_sales / historical_months : fallback_sales
      
      # Meta baseada na média histórica + 10% de crescimento
      fallback_target = (average_monthly_sales * 1.1).round(2)
      
      fallback_days_total = fallback_end.day
      fallback_days_elapsed = current_date.day
      # Usar o método correto para calcular dias restantes considerando escalas
      fallback_days_remaining = calculate_goal_days_remaining(seller, current_date, fallback_end)
      
      fallback_daily_target = fallback_days_remaining > 0 ? ((fallback_target - fallback_sales) / fallback_days_remaining).round(2) : 0
      
      # Calcular métricas reais
      store_orders_count = store_orders_month.count
      store_total_items = store_orders_month.joins(:order_items).sum('order_items.quantity')
      store_ticket_medio = store_orders_count > 0 ? fallback_sales / store_orders_count : 0
      store_pa = store_orders_count > 0 ? store_total_items.to_f / store_orders_count : 0
      
      store_goals_data << {
        id: nil,
        seller_id: nil,
        seller_name: "Loja #{store.name}",
        tipo: 'mensal',
        nome_periodo: "Mensal (#{fallback_days_total} dias)",
        inicio: fallback_start.strftime("%d/%m/%Y"),
        fim: fallback_end.strftime("%d/%m/%Y"),
        meta_valor: fallback_target,
        vendas_realizadas: fallback_sales,
        
        percentual_atingido: fallback_target > 0 ? (fallback_sales / fallback_target * 100).round(2) : 0,
        dias_total: fallback_days_total,
        dias_decorridos: fallback_days_elapsed,
        dias_restantes: fallback_days_remaining,
        meta_por_dia_restante: fallback_daily_target,
        quanto_falta_super_meta: [(fallback_target * 1.2) - fallback_sales, 0].max.round(2),
        ticket_medio: store_ticket_medio.round(2),
        pa_produtos_atendimento: store_pa.round(1),
        pedidos_count: store_orders_count,
        produtos_vendidos: store_total_items,
        meta_data: {
          inicio_iso: fallback_start.iso8601,
          fim_iso: fallback_end.iso8601,
          goal_type: 'sales',
          goal_scope: 'store'
        }
      }
    end
    
    # Calcular KPIs consolidados da loja
    total_sellers = store_sellers.count
    active_goals_count = store_goals_data.length
    
    # Usar a meta principal (primeira ou maior) para cálculos gerais
    primary_goal = store_goals_data.first
    total_target = primary_goal[:meta_valor]
    total_sales = primary_goal[:vendas_realizadas]
    total_percentage = primary_goal[:percentual_atingido]
    total_days_remaining = primary_goal[:dias_restantes]
    total_daily_target = primary_goal[:meta_por_dia_restante]
    
    # Calcular métricas dos últimos 7 dias
    last_7_days_sales = calculate_store_last_sales_days(store, 7)
    
    # Dados do manager
    kpi_data = {
      # Informações do manager
      manager: {
        id: manager.id,
        name: manager.display_name,
        email: manager.email,
        telefone: manager.formatted_whatsapp
      },
      
      # Informações da loja
      store: {
        id: store.id,
        name: store.name,
        slug: store.slug,
        total_sellers: total_sellers,
        active_goals: active_goals_count
      },
      
      # Informações da empresa
      company: {
        id: manager.company.id,
        name: manager.company.name
      },
      
      # === ARRAY DINÂMICO DE METAS DA LOJA ===
      metas_loja: store_goals_data,
      
      # === DADOS CONSOLIDADOS ===
      consolidado: {
        meta_total: total_target,
        vendas_realizadas: total_sales,
        percentual_atingido: total_percentage,
        dias_restantes: total_days_remaining,
        meta_por_dia_restante: total_daily_target,
        quanto_falta_super_meta: primary_goal[:quanto_falta_super_meta],
        ticket_medio: primary_goal[:ticket_medio],
        pa_produtos_atendimento: primary_goal[:pa_produtos_atendimento],
        pedidos_count: primary_goal[:pedidos_count],
        produtos_vendidos: primary_goal[:produtos_vendidos]
      },
      
      # === ÚLTIMOS 7 DIAS ===
      ultimos_7_dias: last_7_days_sales,
      
      # === METADADOS ===
      metadados: {
        data_atual: current_date.iso8601,
        total_metas_ativas: active_goals_count,
        tipos_metas: store_goals_data.map { |g| g[:tipo] }.uniq,
        periodo_analise: {
          inicio: store_goals_data.map { |g| g[:meta_data][:inicio_iso] }.min,
          fim: store_goals_data.map { |g| g[:meta_data][:fim_iso] }.max
        }
      }
    }

    render json: kpi_data
  end

  # GET /beta/kpis/:id - KPIs baseados nos campos da planilha
  def kpis
    seller_id = params[:id]
    
    # Buscar vendedor real pelo ID fornecido
    seller = Seller.includes(:store, :company, :goals, :schedules, :shifts, :orders => :order_items).find_by(id: seller_id)
    
    if seller.nil?
      render json: { error: "Vendedor não encontrado" }, status: :not_found
      return
    end
    
    store = seller.store
    current_date = Date.current
    
    # Verificar se o vendedor está trabalhando hoje
    working_today = seller_working_today?(seller, current_date)
    
    # Buscar todas as metas ativas do vendedor
    active_goals = seller.goals.active.order(:start_date)
    
    # Processar cada meta dinamicamente
    goals_data = []
    
    active_goals.each do |goal|
      goal_start = goal.start_date
      goal_end = goal.end_date
      goal_target = goal.target_value
      goal_current_value = goal.current_value || 0
      
      # Calcular vendas líquidas no período da meta
      sales_data = calculate_net_sales(seller, goal_start, goal_end)
      goal_sales = sales_data[:net_sales]
      
      # Buscar pedidos do período da meta
      goal_orders = seller.orders.includes(:order_items)
                         .where('sold_at >= ? AND sold_at <= ?', goal_start, goal_end)
      
      # Calcular métricas do período
      goal_orders_count = goal_orders.count
      goal_total_items = goal_orders.joins(:order_items).sum('order_items.quantity')
      
      # Dias da meta
      goal_total_days = (goal_end - goal_start).to_i + 1
      goal_days_elapsed = [current_date - goal_start + 1, 0].max.to_i
      goal_days_remaining = calculate_goal_days_remaining(goal.seller, current_date, goal_end)
      
      # Calcular percentual e métricas
      goal_percentage = goal_target > 0 ? (goal_sales / goal_target * 100).round(2) : 0
      goal_ticket = goal_orders_count > 0 ? goal_sales / goal_orders_count : 0
      goal_pa = goal_orders_count > 0 ? goal_total_items.to_f / goal_orders_count : 0
      
      # Classificar tipo de período
      goal_type = case goal_total_days
                  when 1..7 then 'diario'
                  when 8..14 then 'semanal'
                  when 15..35 then 'mensal'
                  when 36..100 then 'trimestral'
                  else 'personalizado'
                  end
      
      goals_data << {
        id: goal.id,
        tipo: goal_type,
        nome_periodo: "#{goal_type.capitalize} (#{goal_total_days} dias)",
        inicio: goal_start.strftime("%d/%m/%Y"),
        fim: goal_end.strftime("%d/%m/%Y"),
        meta_valor: goal_target,
        vendas_realizadas: goal_sales,
        percentual_atingido: goal_percentage,
        dias_total: goal_total_days,
        dias_decorridos: goal_days_elapsed,
        dias_restantes: goal_days_remaining,
        meta_recalculada_dia: goal_days_remaining > 0 ? ((goal_target - goal_sales) / goal_days_remaining).round(2) : 0,
        ticket_medio: goal_ticket.round(2),
        pa_produtos_atendimento: goal_pa.round(1),
        pedidos_count: goal_orders_count,
        produtos_vendidos: goal_total_items,
        quanto_falta_super_meta: [(goal_target * 1.2) - goal_sales, 0].max.round(2),
        meta_data: {
          inicio_iso: goal_start.iso8601,
          fim_iso: goal_end.iso8601,
          goal_type: goal.goal_type,
          goal_scope: goal.goal_scope
        }
      }
    end
    
    # Se não há metas, calcular dados reais do vendedor para o mês atual
    if goals_data.empty?
      fallback_start = current_date.beginning_of_month
      fallback_end = current_date.end_of_month
      
      # Calcular vendas líquidas reais do vendedor no mês atual
      fallback_sales_data = calculate_net_sales(seller, fallback_start, [current_date, fallback_end].min)
      fallback_sales = fallback_sales_data[:net_sales]
      
      # Calcular meta baseada na média histórica líquida do vendedor (últimos 3 meses)
      historical_sales_data = calculate_net_sales(seller, 
                                                3.months.ago.beginning_of_month, 
                                                1.month.ago.end_of_month)
      historical_sales = historical_sales_data[:net_sales]
      historical_months = 3
      average_monthly_sales = historical_months > 0 ? historical_sales / historical_months : fallback_sales
      
      # Meta baseada na média histórica + 10% de crescimento
      fallback_target = (average_monthly_sales * 1.1).round(2)
      
      fallback_days_total = fallback_end.day
      fallback_days_elapsed = current_date.day
      fallback_days_remaining = fallback_end.day - current_date.day
      
      # Buscar pedidos do vendedor no mês atual
      seller_orders_month = seller.orders.includes(:order_items)
                                 .where('sold_at >= ? AND sold_at <= ?', fallback_start, [current_date, fallback_end].min)
      
      # Calcular métricas reais
      seller_orders_count = seller_orders_month.count
      seller_total_items = seller_orders_month.joins(:order_items).sum('order_items.quantity')
      seller_ticket_medio = seller_orders_count > 0 ? fallback_sales / seller_orders_count : 0
      seller_pa = seller_orders_count > 0 ? seller_total_items.to_f / seller_orders_count : 0
      
      goals_data << {
        id: nil,
        tipo: 'mensal',
        nome_periodo: "Mensal (#{fallback_days_total} dias)",
        inicio: fallback_start.strftime("%d/%m/%Y"),
        fim: fallback_end.strftime("%d/%m/%Y"),
        meta_valor: fallback_target,
        vendas_realizadas: fallback_sales,
        percentual_atingido: fallback_target > 0 ? (fallback_sales / fallback_target * 100).round(2) : 0,
        dias_total: fallback_days_total,
        dias_decorridos: fallback_days_elapsed,
        dias_restantes: fallback_days_remaining,
        meta_recalculada_dia: fallback_days_remaining > 0 ? ((fallback_target - fallback_sales) / fallback_days_remaining).round(2) : 0,
        ticket_medio: seller_ticket_medio.round(2),
        pa_produtos_atendimento: seller_pa.round(1),
        pedidos_count: seller_orders_count,
        produtos_vendidos: seller_total_items,
        quanto_falta_super_meta: [(fallback_target * 1.2) - fallback_sales, 0].max.round(2),
        meta_data: {
          inicio_iso: fallback_start.iso8601,
          fim_iso: fallback_end.iso8601,
          goal_type: 'sales',
          goal_scope: 'individual'
        }
      }
    end
    
    # Usar a meta principal (primeira ou maior) para cálculos gerais
    primary_goal = goals_data.first
    monthly_target = primary_goal[:meta_valor]
    monthly_sales = primary_goal[:vendas_realizadas]
    monthly_days_remaining = primary_goal[:dias_restantes]
    
    # Calcular métricas da loja baseado na meta principal
    primary_start = Date.parse(primary_goal[:meta_data][:inicio_iso])
    primary_end = Date.parse(primary_goal[:meta_data][:fim_iso])
    
    # Calcular vendas líquidas da loja no período da meta principal
    store_sales_data = calculate_store_net_sales(store, primary_start, [current_date, primary_end].min)
    store_sales = store_sales_data[:net_sales]
    store_orders_count = store_sales_data[:gross_sales] > 0 ? Order.joins(:seller)
                                                                  .where(sellers: { store_id: store.id })
                                                                  .where('orders.sold_at >= ? AND orders.sold_at <= ?', primary_start, [current_date, primary_end].min)
                                                                  .count : 0
    store_total_items = store_orders_count > 0 ? Order.joins(:seller, :order_items)
                                                    .where(sellers: { store_id: store.id })
                                                    .where('orders.sold_at >= ? AND orders.sold_at <= ?', primary_start, [current_date, primary_end].min)
                                                    .sum('order_items.quantity') : 0
    # Calcular meta da loja baseada no número real de vendedores ativos
    active_sellers_count = store.sellers.where(active_until: nil).or(store.sellers.where('active_until > ?', current_date)).count
    store_target = monthly_target * [active_sellers_count, 1].max # Mínimo de 1 vendedor
    
    # Calcular KPIs conforme planilha (baseado na meta principal)
    seller_ticket = primary_goal[:ticket_medio]
    store_ticket = store_orders_count > 0 ? store_sales / store_orders_count : 0
    seller_pa = primary_goal[:pa_produtos_atendimento]
    store_pa = store_orders_count > 0 ? store_total_items.to_f / store_orders_count : 0
    
    # Percentuais
    seller_percentage = primary_goal[:percentual_atingido]
    store_percentage = store_target > 0 ? (store_sales / store_target * 100).round(2) : 0
    

 
    
    # Calcular últimos 7 dias com vendas
    last_sales_days = calculate_last_sales_days(seller, 7)
    
    # Dados conforme planilha
    kpi_data = {
      # Campos básicos da planilha
      telefone: seller.formatted_whatsapp,
      nome: seller.display_name,
      id: seller.id, # ID real do vendedor
      primeiro_nome: format_name(seller.first_name),
      
      # Status de trabalho
      trabalhando_hoje: working_today,
      
      # Últimos dias com vendas
      ultimos_dias_trabalhados: last_sales_days,
      
      # === ARRAY DINÂMICO DE METAS ===
      metas: goals_data,
      
      # === DADOS CONSOLIDADOS (baseados na meta principal) ===
      meta_principal: {
        meta_valor: primary_goal[:meta_valor],
        vendas_realizadas: primary_goal[:vendas_realizadas],
        percentual_atingido: primary_goal[:percentual_atingido],
        tipo_periodo: primary_goal[:tipo],
        inicio: primary_goal[:inicio],
        fim: primary_goal[:fim],
        dias_restantes: primary_goal[:dias_restantes],
        meta_recalculada_dia: primary_goal[:meta_recalculada_dia],
        quanto_falta_super_meta: primary_goal[:quanto_falta_super_meta]
      },
      
      # === DADOS DA LOJA ===
      loja: {
        total_vendas: store_sales,
        ticket_medio: store_ticket.round(2),
        meta_periodo: store_target,
        percentual_atingido: store_percentage,
        pa_produtos_atendimento: store_pa.round(1),
        pedidos_count: store_orders_count,
        produtos_vendidos: store_total_items
      },
      
      # === DADOS DO VENDEDOR ===
      vendedor: {
        ticket_medio: seller_ticket,
        pa_produtos_atendimento: seller_pa,
        comissao_calculada: 0,
        percentual_comissao: 0,
        total_metas_ativas: goals_data.length
      },
      
      # === NÍVEIS DE COMISSÃO ===
      commission_levels: [],
      
      # === METADADOS ===
      metadados: {
        data_atual: current_date.iso8601,
        total_metas_ativas: goals_data.length,
        tipos_metas: goals_data.map { |g| g[:tipo] }.uniq,
        periodo_analise: {
          inicio: goals_data.map { |g| g[:meta_data][:inicio_iso] }.min,
          fim: goals_data.map { |g| g[:meta_data][:fim_iso] }.max
        }
      }
    }

    # Telefone já está sendo definido com o valor real do vendedor acima

    render json: kpi_data
  end

  private

  # Calcula dias restantes considerando escalas quando existem
  def calculate_goal_days_remaining(seller, current_date, goal_end)
    # Primeiro, calcular dias restantes baseado na data da meta
    calendar_days_remaining = [goal_end - current_date, 0].max.to_i
    
    # Se não há dias restantes na meta, retornar 0
    return 0 if calendar_days_remaining == 0
    
    # Verificar se há escalas definidas para o período restante
    scheduled_days = seller.schedules
                           .where(date: current_date..goal_end)
                           .count
    
    # Se há escalas definidas, usar o número de dias escalados
    # Caso contrário, usar dias úteis (excluindo apenas domingos)
    if scheduled_days > 0
      scheduled_days
    else
      (current_date..goal_end).count { |date| !date.sunday? }
    end
  end

  # Calcula vendas líquidas considerando devoluções e trocas
  def calculate_net_sales(seller, start_date, end_date)
    # Vendas brutas
    gross_orders = seller.orders.includes(:order_items)
                        .where('sold_at >= ? AND sold_at <= ?', start_date, end_date)
    gross_sales = gross_orders.joins(:order_items)
                             .sum('order_items.quantity * order_items.unit_price')
    
    # Devoluções
    returns = Return.where(seller_id: seller.id)
                   .where('returns.processed_at >= ? AND returns.processed_at <= ?', start_date, end_date)
    total_returned = returns.sum(&:return_value)
    
    # Trocas
    exchanges = Exchange.where(seller_id: seller.id)
                       .where('processed_at >= ? AND processed_at <= ?', start_date, end_date)
    credit_exchanges = exchanges.where(is_credit: true).sum(:voucher_value)
    debit_exchanges = exchanges.where(is_credit: false).sum(:voucher_value)
    
    # Valor líquido = Vendas brutas - Devoluções + Trocas a crédito - Trocas a débito
    net_sales = gross_sales - total_returned + credit_exchanges - debit_exchanges
    
    {
      gross_sales: gross_sales,
      total_returned: total_returned,
      credit_exchanges: credit_exchanges,
      debit_exchanges: debit_exchanges,
      net_sales: net_sales
    }
  end

  # Calcula vendas líquidas da loja considerando devoluções e trocas
  def calculate_store_net_sales(store, start_date, end_date)
    # Vendas brutas da loja
    gross_orders = Order.joins(:seller)
                       .where(sellers: { store_id: store.id })
                       .includes(:order_items)
                       .where('orders.sold_at >= ? AND orders.sold_at <= ?', start_date, end_date)
    gross_sales = gross_orders.joins(:order_items)
                             .sum('order_items.quantity * order_items.unit_price')
    
    # Devoluções da loja
    returns = Return.where(store_id: store.id)
                   .where('returns.processed_at >= ? AND returns.processed_at <= ?', start_date, end_date)
    total_returned = returns.sum(&:return_value)
    
    # Trocas da loja
    exchanges = Exchange.joins(:seller)
                       .where(sellers: { store_id: store.id })
                       .where('processed_at >= ? AND processed_at <= ?', start_date, end_date)
    credit_exchanges = exchanges.where(is_credit: true).sum(:voucher_value)
    debit_exchanges = exchanges.where(is_credit: false).sum(:voucher_value)
    
    # Valor líquido = Vendas brutas - Devoluções + Trocas a crédito - Trocas a débito
    net_sales = gross_sales - total_returned + credit_exchanges - debit_exchanges
    
    {
      gross_sales: gross_sales,
      total_returned: total_returned,
      credit_exchanges: credit_exchanges,
      debit_exchanges: debit_exchanges,
      net_sales: net_sales
    }
  end

  def seller_working_today?(seller, date)
    # Verificar se o vendedor tem um agendamento de turno para hoje
    today_schedules = seller.schedules.joins(:shift)
                           .where(date: date)
    
    # Se tem agendamentos para hoje, está trabalhando
    return true if today_schedules.any?
    
    # Se não tem agendamentos específicos, assumir que está trabalhando (fallback)
    # ou verificar se está ativo e não ausente
    seller.active? && !seller.absent?
  end

  def format_name(name)
    return "" if name.blank?
    
    # Converte para string, remove espaços extras e capitaliza
    # (primeira letra maiúscula, demais minúsculas)
    name.to_s.strip.capitalize
  end

  def calculate_last_sales_days(seller, limit = 7)
    # Buscar os últimos dias únicos com vendas do vendedor
    sales_dates = seller.orders
                       .joins(:order_items)
                       .where('order_items.quantity > 0 AND order_items.unit_price > 0')
                       .where('orders.sold_at IS NOT NULL')
                       .group('DATE(orders.sold_at)')
                       .order('DATE(orders.sold_at) DESC')
                       .limit(limit)
                       .pluck('DATE(orders.sold_at)')
    
    # Calcular vendas para cada dia
    sales_days = sales_dates.map do |date|
      # Calcular vendas líquidas para o dia específico
      day_sales_data = calculate_net_sales(seller, date, date)
      day_sales = day_sales_data[:net_sales]
      
      day_orders = seller.orders.includes(:order_items)
                        .where('DATE(orders.sold_at) = ?', date)
      
      day_orders_count = day_orders.count
      day_items_count = day_orders.joins(:order_items).sum('order_items.quantity')
      
      {
        data: date.strftime("%d/%m/%Y"),
        data_iso: date.iso8601,
        dia_semana: I18n.l(date, format: "%A"),
        vendas: day_sales.round(2),
        pedidos: day_orders_count,
        itens: day_items_count,
        ticket_medio: day_orders_count > 0 ? (day_sales / day_orders_count).round(2) : 0
      }
    end
    
    sales_days
  end

  def calculate_store_last_sales_days(store, limit = 7)
    # Buscar os últimos dias únicos com vendas da loja
    sales_dates = Order.joins(:seller)
                      .joins(:order_items)
                      .where(sellers: { store_id: store.id })
                      .where('order_items.quantity > 0 AND order_items.unit_price > 0')
                      .where('orders.sold_at IS NOT NULL')
                      .group('DATE(orders.sold_at)')
                      .order('DATE(orders.sold_at) DESC')
                      .limit(limit)
                      .pluck('DATE(orders.sold_at)')
    
    # Calcular vendas para cada dia
    sales_days = sales_dates.map do |date|
      # Calcular vendas líquidas da loja para o dia específico
      day_sales_data = calculate_store_net_sales(store, date, date)
      day_sales = day_sales_data[:net_sales]
      
      day_orders = Order.joins(:seller)
                       .includes(:order_items)
                       .where(sellers: { store_id: store.id })
                       .where('DATE(orders.sold_at) = ?', date)
      
      day_orders_count = day_orders.count
      day_items_count = day_orders.joins(:order_items).sum('order_items.quantity')
      
      {
        data: date.strftime("%d/%m/%Y"),
        data_iso: date.iso8601,
        dia_semana: I18n.l(date, format: "%A"),
        vendas: day_sales.round(2),
        pedidos: day_orders_count,
        itens: day_items_count,
        ticket_medio: day_orders_count > 0 ? (day_sales / day_orders_count).round(2) : 0
      }
    end
    
    sales_days
  end
end
