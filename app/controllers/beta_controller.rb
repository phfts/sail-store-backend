class BetaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:sellers, :kpis, :managers]

  # GET /beta/sellers
  def sellers
    # Buscar beta_seller pelo nome (vendedora em beta)
    beta_seller =  Seller.find_by_name('ELAINE DIOGO PAULO')
    beta_seller_2 =  Seller.find_by_name('BARBARA DA SILVA GUIMARAES')

    if beta_seller
      # Retornar array com o ID real da beta_seller
      render json: [
        {id: beta_seller.id, name: beta_seller.name, telefone: '+55 (19) 98873-2450' }, 
        {id: beta_seller_2.id, name: beta_seller_2.name, telefone: '+55 (11) 99999-2450' }
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
        telefone: manager.formatted_whatsapp,
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
      
      # Calcular vendas no período da meta
      goal_orders = seller.orders.includes(:order_items)
                         .where('sold_at >= ? AND sold_at <= ?', goal_start, goal_end)
      goal_sales = goal_orders.joins(:order_items)
                             .sum('order_items.quantity * order_items.unit_price')
      
      # Calcular métricas do período
      goal_orders_count = goal_orders.count
      goal_total_items = goal_orders.joins(:order_items).sum('order_items.quantity')
      
      # Dias da meta
      goal_total_days = (goal_end - goal_start).to_i + 1
      goal_days_elapsed = [current_date - goal_start + 1, 0].max.to_i
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
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
        pa_produtos_atendimento: goal_pa.round(2),
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
    
    # Se não há metas, criar fallback
    if goals_data.empty?
      fallback_start = current_date.beginning_of_month
      fallback_end = current_date.end_of_month
      fallback_target = 15000.0
      fallback_sales = 8750.0
      fallback_days_total = fallback_end.day
      fallback_days_elapsed = current_date.day
      fallback_days_remaining = fallback_end.day - current_date.day
      
      goals_data << {
        id: nil,
        tipo: 'mensal',
        nome_periodo: "Mensal (#{fallback_days_total} dias)",
        inicio: fallback_start.strftime("%d/%m/%Y"),
        fim: fallback_end.strftime("%d/%m/%Y"),
        meta_valor: fallback_target,
        vendas_realizadas: fallback_sales,
        percentual_atingido: (fallback_sales / fallback_target * 100).round(2),
        dias_total: fallback_days_total,
        dias_decorridos: fallback_days_elapsed,
        dias_restantes: fallback_days_remaining,
        meta_recalculada_dia: fallback_days_remaining > 0 ? ((fallback_target - fallback_sales) / fallback_days_remaining).round(2) : 0,
        ticket_medio: 0,
        pa_produtos_atendimento: 0,
        pedidos_count: 0,
        produtos_vendidos: 0,
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
    
    store_orders = Order.joins(:seller)
                        .where(sellers: { store_id: store.id })
                        .includes(:order_items)
                        .where('orders.sold_at >= ? AND orders.sold_at <= ?', primary_start, [current_date, primary_end].min)
    store_sales = store_orders.joins(:order_items).sum('order_items.quantity * order_items.unit_price')
    store_orders_count = store_orders.count
    store_total_items = store_orders.joins(:order_items).sum('order_items.quantity')
    store_target = monthly_target * 8 # assumindo 8 vendedores
    
    # Calcular KPIs conforme planilha (baseado na meta principal)
    seller_ticket = primary_goal[:ticket_medio]
    store_ticket = store_orders_count > 0 ? store_sales / store_orders_count : 0
    seller_pa = primary_goal[:pa_produtos_atendimento]
    store_pa = store_orders_count > 0 ? store_total_items.to_f / store_orders_count : 0
    
    # Percentuais
    seller_percentage = primary_goal[:percentual_atingido]
    store_percentage = store_target > 0 ? (store_sales / store_target * 100).round(2) : 0
    
    # Comissão - usar commission_levels ou fallback simples
    commission_levels = store.commission_levels.order(:achievement_percentage)
    if commission_levels.any?
      current_level = commission_levels.where('achievement_percentage <= ?', seller_percentage).last
      commission_rate = current_level&.commission_percentage || 3.5
    else
      # Níveis simples baseados em performance
      commission_rate = case seller_percentage
                       when 0..69.99 then 3.5
                       when 70..89.99 then 4.0
                       when 90..109.99 then 4.5
                       else 5.0
                       end
    end
    
    commission_amount = monthly_sales * (commission_rate / 100)
    
    # Calcular últimos 7 dias com vendas
    last_sales_days = calculate_last_sales_days(seller, 7)
    
    # Dados conforme planilha
    kpi_data = {
      # Campos básicos da planilha
      telefone: seller.formatted_whatsapp || "+55 (11) 99999-9999",
      nome: seller.display_name || "Vendedor Mock",
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
        pa_produtos_atendimento: store_pa.round(2),
        pedidos_count: store_orders_count,
        produtos_vendidos: store_total_items
      },
      
      # === DADOS DO VENDEDOR ===
      vendedor: {
        ticket_medio: seller_ticket,
        pa_produtos_atendimento: seller_pa,
        comissao_calculada: commission_amount.round(2),
        percentual_comissao: commission_rate,
        total_metas_ativas: goals_data.length
      },
      
      # === NÍVEIS DE COMISSÃO ===
      commission_levels: commission_levels.any? ? 
        commission_levels.map { |cl| { level: cl.achievement_percentage, commission: cl.commission_percentage } } :
        [
          { level: 70.0, commission: 3.5 },
          { level: 80.0, commission: 4.0 },
          { level: 90.0, commission: 4.5 },
          { level: 100.0, commission: 5.0 }
        ],
      
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
      day_orders = seller.orders.includes(:order_items)
                        .where('DATE(orders.sold_at) = ?', date)
      
      day_sales = day_orders.joins(:order_items)
                           .sum('order_items.quantity * order_items.unit_price')
      
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
