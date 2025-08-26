class DashboardController < ApplicationController
  before_action :require_admin!, only: [:admin_dashboard]
  before_action :ensure_store_access, only: [:store_dashboard]

  # GET /dashboard (admin dashboard)
  def admin_dashboard
    render json: {
      totalStores: Store.count,
      totalUsers: User.count,
      totalSellers: Seller.count,
      monthlyActiveUsers: User.where('last_sign_in_at >= ?', 1.month.ago).count,
      weeklyActiveUsers: User.where('last_sign_in_at >= ?', 1.week.ago).count,
      dailyActiveUsers: User.where('last_sign_in_at >= ?', 1.day.ago).count
    }
  end

  # GET /stores/:slug/dashboard
  def store_dashboard
    store = Store.find_by!(slug: params[:slug])
    
    # Verificar acesso
    unless current_user.admin? || (current_user.store&.id == store.id)
      render json: { error: "Acesso negado" }, status: :forbidden
      return
    end

    # Determinar período baseado no parâmetro
    period = params[:period] || 'all-time'
    date_range = calculate_date_range(period)

    # Buscar dados dos vendedores
    sellers = store.sellers.includes(:user)
    active_sellers = sellers.select(&:active?)
    
    # Buscar vendedores em férias
    sellers_on_vacation = sellers.joins(:absences)
      .where('absences.start_date <= ? AND absences.end_date >= ?', Date.current, Date.current)
      .distinct

    # Buscar turnos
    shifts = store.shifts
    active_shifts = shifts

    # Buscar escalas
    schedules = store.schedules
    current_date = Date.current
    
    # Buscar próxima escala (próximo dia com vendedores escalados)
    next_scheduled_day = nil
    next_scheduled_sellers_count = 0
    
    # Verificar próximos 14 dias a partir de amanhã para garantir que encontramos a próxima escala
    (1..14).each do |day_offset|
      check_date = current_date + day_offset.days
      
      scheduled_sellers = schedules.where(date: check_date).count
      
      if scheduled_sellers > 0
        next_scheduled_day = check_date
        next_scheduled_sellers_count = scheduled_sellers
        break
      end
    end

    # Buscar ausências
    absences = store.absences
    active_absences = absences.where('start_date <= ? AND end_date >= ?', Date.current, Date.current)

    # Calcular vendas a partir dos order items
    orders = store.orders.includes(:seller, :order_items)
    
    # Calcular trocas e devoluções totais da loja para descontar do total
    total_exchanges_value = Exchange.joins(:seller).where(sellers: { store_id: store.id }).sum(:voucher_value)
    total_returns_value = calculate_total_returns_value(store)
    total_adjustments = total_exchanges_value + total_returns_value
    
    # Vendas do mês atual
    current_month_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_month, Date.current.end_of_month)
    current_month_sales_gross = calculate_sales_from_orders(current_month_orders)
    # Trocas/devoluções do mês atual
    current_month_exchanges = Exchange.joins(:seller)
      .where(sellers: { store_id: store.id })
      .where('processed_at >= ? AND processed_at <= ?', 
        Date.current.beginning_of_month, Date.current.end_of_month)
      .sum(:voucher_value)
    current_month_returns = calculate_period_returns_value(store, Date.current.beginning_of_month, Date.current.end_of_month)
    current_month_sales = current_month_sales_gross - current_month_exchanges - current_month_returns
    
    # Vendas da semana atual
    current_week_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_week, Date.current.end_of_week)
    current_week_sales_gross = calculate_sales_from_orders(current_week_orders)
    # Trocas/devoluções da semana atual
    current_week_exchanges = Exchange.joins(:seller)
      .where(sellers: { store_id: store.id })
      .where('processed_at >= ? AND processed_at <= ?', 
        Date.current.beginning_of_week, Date.current.end_of_week)
      .sum(:voucher_value)
    current_week_returns = calculate_period_returns_value(store, Date.current.beginning_of_week, Date.current.end_of_week)
    current_week_sales = current_week_sales_gross - current_week_exchanges - current_week_returns
    
    # Vendas de hoje
    today_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_day, Date.current.end_of_day)
    today_sales_gross = calculate_sales_from_orders(today_orders)
    # Trocas/devoluções de hoje
    today_exchanges = Exchange.joins(:seller)
      .where(sellers: { store_id: store.id })
      .where('processed_at >= ? AND processed_at <= ?', 
        Date.current.beginning_of_day, Date.current.end_of_day)
      .sum(:voucher_value)
    today_returns = calculate_period_returns_value(store, Date.current.beginning_of_day, Date.current.end_of_day)
    today_sales = today_sales_gross - today_exchanges - today_returns
    
    # Total de vendas líquidas (todos os pedidos menos trocas/devoluções)
    total_sales_gross = calculate_sales_from_orders(orders)
    total_sales = total_sales_gross - total_adjustments
    
    # Calcular Ticket Médio e PA (Produto por Atendimento)
    current_month_metrics = calculate_metrics(current_month_orders)
    current_week_metrics = calculate_metrics(current_week_orders)
    today_metrics = calculate_metrics(today_orders)
    total_metrics = calculate_metrics(orders)
    
    # Buscar metas ativas
    current_goals = store.goals.where('end_date >= ?', Date.current)
    current_target = current_goals.sum(:target_value)
    
    # Buscar todas as metas (ativas e inativas) para incluir no retorno
    all_goals = Goal.joins(:seller)
                    .where(sellers: { store_id: store.id })
                    .includes(:seller)
                    .order(:end_date)
    
    # Calcular progresso baseado nas vendas reais
    progress = current_target > 0 ? ((current_month_sales.to_f / current_target) * 100).round(2) : 0

    # Calcular Potencial de Vendas (isso também calcula a melhor média)
    potencial_vendas = calculate_sales_potential(store, orders, active_sellers, date_range)
    best_average_per_day = potencial_vendas[:best_seller_average]

    # Otimização: buscar todos os dados de uma vez para evitar N+1 queries
    seller_ids = active_sellers.map(&:id)
    
    # Buscar todas as vendas dos vendedores no período de uma vez
    all_seller_orders = orders.where(seller_id: seller_ids)
                             .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                    date_range[:start_date], date_range[:end_date])
                             .includes(:order_items)
    
    # Buscar todas as devoluções dos vendedores no período de uma vez
    all_seller_returns = Return.where(seller_id: seller_ids)
                              .where('returns.processed_at >= ? AND returns.processed_at <= ?', 
                                     date_range[:start_date], date_range[:end_date])
    
    # Buscar todas as trocas dos vendedores no período de uma vez
    all_seller_exchanges = Exchange.joins(:seller)
                                  .where(sellers: { id: seller_ids })
                                  .where('exchanges.processed_at >= ? AND exchanges.processed_at <= ?', 
                                         date_range[:start_date], date_range[:end_date])
    
    # Dados de vendedores baseados no período selecionado
    sellers_annual_data = active_sellers.map do |seller|
      # Filtrar dados deste vendedor
      seller_orders = all_seller_orders.select { |order| order.seller_id == seller.id }
      seller_returns = all_seller_returns.select { |ret| ret.seller_id == seller.id }
      seller_exchanges = all_seller_exchanges.select { |exc| exc.seller_id == seller.id }
      
      seller_sales = calculate_sales_from_orders(seller_orders)
      seller_metrics = calculate_metrics(seller_orders)
      
      # Calcular vendas brutas
      seller_sales = seller_orders.sum(&:total)
      
      # Calcular trocas e devoluções reais do vendedor
      total_returns_value = seller_returns.sum(&:return_value)
      total_returns_count = seller_returns.count
      
      # Trocas reais do vendedor (separar crédito e débito)
      credit_exchanges = seller_exchanges.select { |exc| exc.is_credit }.sum(&:voucher_value)
      debit_exchanges = seller_exchanges.select { |exc| !exc.is_credit }.sum(&:voucher_value)
      total_exchanges_count = seller_exchanges.count
      
      # Total de devoluções e trocas (que reduzem vendas)
      total_returns_exchanges_value = total_returns_value + debit_exchanges + credit_exchanges
      total_returns_exchanges_count = total_returns_count + total_exchanges_count
      
      # Vendas líquidas = Vendas brutas - Devoluções - Trocas a débito - Trocas a crédito
      net_sales = seller_sales - total_returns_value - debit_exchanges - credit_exchanges
      
      # Calcular dias que o vendedor vai trabalhar no mês atual baseado na escala
      current_month_work_days = calculate_seller_work_days_in_month(seller, Date.current)
      
      # Calcular potencial individual (melhor média de vendas por dia × dias que vai trabalhar no mês)
      daily_sales = {}
      seller_orders.each do |order|
        date_key = order.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        daily_sales[date_key] += calculate_sales_from_orders([order])
      end
      
      days_worked = daily_sales.keys.count
      average_per_day = days_worked > 0 ? (net_sales.to_f / days_worked) : 0
      individual_potential = best_average_per_day * current_month_work_days
      
      # Calcular comissão do vendedor baseada nos níveis configurados
      commission = calculate_seller_commission(seller, net_sales, store)
      
      {
        id: seller.id,
        name: seller.name,
        sales: seller_sales,
        net_sales: net_sales.round(2),
        potential: individual_potential.round(2),
        ticket_medio: seller_orders.count > 0 ? (net_sales / seller_orders.count).round(2) : 0,
        produtos_por_atendimento: seller_metrics[:produtos_por_atendimento],
        days_worked: days_worked,
        average_per_day: average_per_day.round(2),
        average_orders_per_day: days_worked > 0 ? (seller_orders.count.to_f / days_worked).round(2) : 0,
        returns_exchanges_value: total_returns_exchanges_value.round(2),
        returns_exchanges_count: total_returns_exchanges_count,
        commission: commission.round(2),
        avatar: nil
      }
    end.sort_by { |seller| -seller[:sales] }

    # Top vendedores (primeiros 3)
    top_sellers = sellers_annual_data.first(3)

    render json: {
      store: {
        id: store.id,
        name: store.name,
        slug: store.slug,
        cnpj: store.cnpj,
        address: store.address
      },
      sellers: {
        total: sellers.count,
        active: active_sellers.count,
        onVacation: sellers_on_vacation.count
      },
      shifts: {
        total: shifts.count,
        active: active_shifts.count
      },
      schedules: {
        total: schedules.count,
        nextSchedule: next_scheduled_day ? {
          date: next_scheduled_day.strftime("%d/%m/%Y"),
          dayName: next_scheduled_day.strftime("%A"),
          sellersCount: next_scheduled_sellers_count
        } : nil
      },
      absences: {
        total: absences.count,
        active: active_absences.count
      },
      sales: {
        total: total_sales,
        currentMonth: current_month_sales,
        currentWeek: current_week_sales,
        today: today_sales,
        averagePerDay: current_month_orders.count > 0 ? (current_month_sales / Date.current.day).round(2) : 0,
        monthlyBreakdown: calculate_monthly_net_sales(store, orders)
      },
      orderCount: {
        total: orders.count,
        currentMonth: current_month_orders.count,
        currentWeek: current_week_orders.count,
        today: today_orders.count,
        month: current_month_orders.count
      },
      metrics: {
        ticketMedio: {
          total: total_metrics[:ticket_medio],
          currentMonth: current_month_metrics[:ticket_medio],
          currentWeek: current_week_metrics[:ticket_medio],
          today: today_metrics[:ticket_medio],
          month: current_month_metrics[:ticket_medio]
        },
        produtosPorAtendimento: {
          total: total_metrics[:produtos_por_atendimento],
          currentMonth: current_month_metrics[:produtos_por_atendimento],
          currentWeek: current_week_metrics[:produtos_por_atendimento],
          today: today_metrics[:produtos_por_atendimento],
          month: current_month_metrics[:produtos_por_atendimento]
        },
        precoMedio: {
          total: store.orders.joins(:order_items).average('order_items.unit_price') || 0,
          currentMonth: current_month_orders.joins(:order_items).average('order_items.unit_price') || 0,
          currentWeek: current_week_orders.joins(:order_items).average('order_items.unit_price') || 0,
          today: today_orders.joins(:order_items).average('order_items.unit_price') || 0,
          month: current_month_orders.joins(:order_items).average('order_items.unit_price') || 0
        }
      },
      targets: {
        current: current_month_sales,
        target: current_target,
        progress: progress,
        period: "mensal",
        endDate: Date.current.end_of_month.strftime("%d/%m/%Y")
      },
      salesPotential: {
        potential: potencial_vendas[:potential],
        bestSellerAverage: potencial_vendas[:best_seller_average],
        totalWorkDays: potencial_vendas[:total_work_days],
        bestSeller: potencial_vendas[:best_seller],
        bestSellerWeek: calculate_best_seller_week(store, active_sellers)
      },
      topSellers: top_sellers,
      sellersAnnualData: sellers_annual_data,
      goals: all_goals.map do |goal|
        {
          id: goal.id,
          seller_id: goal.seller_id,
          target_value: goal.target_value,
          current_value: goal.current_value || 0,
          start_date: goal.start_date.strftime("%Y-%m-%d"),
          end_date: goal.end_date.strftime("%Y-%m-%d"),
          goal_scope: goal.goal_scope,
          seller: goal.seller ? {
            id: goal.seller.id,
            name: goal.seller.name
          } : nil
        }
      end
    }
  end

  private

  def calculate_sales_from_orders(orders)
    # Otimização: usar SQL para calcular o total em vez de loops
    return 0 if orders.empty?
    
    # Se orders já tem order_items carregados, usar os dados em memória
    if orders.first.association(:order_items).loaded?
      total = 0
      orders.each do |order|
        order.order_items.each do |item|
          total += item.quantity * item.unit_price
        end
      end
      total
    else
      # Usar SQL para calcular o total
      orders.joins(:order_items).sum('order_items.quantity * order_items.unit_price')
    end
  end

  def calculate_metrics(orders)
    order_count = orders.count
    
    if order_count == 0
      return {
        ticket_medio: 0.0,
        produtos_por_atendimento: 0.0
      }
    end
    
    # Calcular valor total vendido
    total_sales = calculate_sales_from_orders(orders)
    
    # Calcular quantidade total de itens - otimização
    total_items = if orders.first.association(:order_items).loaded?
      # Se order_items já está carregado, usar dados em memória
      total = 0
      orders.each do |order|
        order.order_items.each do |item|
          total += item.quantity
        end
      end
      total
    else
      # Usar SQL para calcular o total
      orders.joins(:order_items).sum('order_items.quantity')
    end
    
    # Ticket Médio = Valor total vendido / Número de pedidos
    ticket_medio = (total_sales.to_f / order_count).round(2)
    
    # PA (Produto por Atendimento) = Quantidade total de itens / Número de pedidos
    produtos_por_atendimento = (total_items.to_f / order_count).round(2)
    
    {
      ticket_medio: ticket_medio,
      produtos_por_atendimento: produtos_por_atendimento
    }
  end

  def calculate_sales_potential(store, orders, active_sellers, date_range = nil)
    return {
      potential: 0.0,
      best_seller_average: 0.0,
      total_work_days: 0,
      best_seller: nil
    } if active_sellers.empty?

    # Usar período de 6 meses para encontrar a melhor média diária baseada nos dias trabalhados
    analysis_start_date = 6.months.ago.beginning_of_month
    analysis_end_date = Date.current.end_of_day

    # Otimização: buscar todos os dados de uma vez para evitar N+1 queries
    seller_ids = active_sellers.map(&:id)
    
    # Buscar todas as vendas dos vendedores ativos nos últimos 6 meses de uma vez
    all_seller_orders = Order.joins(:order_items, :seller)
                            .where(seller_id: seller_ids)
                            .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                   analysis_start_date, analysis_end_date)
                            .select('orders.seller_id, orders.sold_at, order_items.quantity, order_items.unit_price')
    
    # Agrupar por vendedor e calcular médias
    seller_averages = active_sellers.map do |seller|
      # Filtrar pedidos deste vendedor
      seller_orders_data = all_seller_orders.select { |order| order.seller_id == seller.id }
      
      # Calcular vendas por dia para este vendedor
      daily_sales = {}
      seller_orders_data.each do |order_data|
        date_key = order_data.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        daily_sales[date_key] += order_data.quantity * order_data.unit_price
      end
      
      # Calcular média de vendas por dia
      total_sales = daily_sales.values.sum
      days_worked = daily_sales.keys.count
      average_per_day = days_worked > 0 ? (total_sales.to_f / days_worked) : 0
      
      {
        seller: seller,
        average_per_day: average_per_day,
        total_sales: total_sales,
        days_worked: days_worked,
        work_dates: daily_sales.keys
      }
    end

    # Filtrar apenas vendedores com mais de 10 dias de vendas para calcular a melhor média
    qualified_sellers = seller_averages.select { |data| data[:days_worked] > 10 }
    
    # Se não há vendedores qualificados, usar todos os vendedores
    sellers_for_best_average = qualified_sellers.empty? ? seller_averages : qualified_sellers
    
    # Encontrar o vendedor com melhor média de vendas por dia (apenas entre os qualificados)
    best_seller_data = sellers_for_best_average.max_by { |data| data[:average_per_day] }
    
    return {
      potential: 0.0,
      best_seller_average: 0.0,
      total_work_days: 0,
      best_seller: nil
    } if best_seller_data.nil? || best_seller_data[:average_per_day] == 0

    # A melhor média de vendas por dia da loja é a do melhor vendedor
    best_average_per_day = best_seller_data[:average_per_day]
    
    # Calcular potencial: melhor média de vendas por dia × dias que cada vendedor vai trabalhar no mês atual
    # Considerar apenas vendedores com vendas significativas (> R$ 500) no mês atual
    total_potential = 0
    active_sellers_with_sales = 0
    
    seller_averages.each do |data|
      # Verificar se o vendedor teve vendas significativas no mês atual
      current_month_sales = data[:seller].orders
                                        .joins(:order_items)
                                        .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                               Date.current.beginning_of_month, Date.current.end_of_day)
                                        .sum('order_items.quantity * order_items.unit_price')
      
      # Só incluir no potencial se teve vendas > R$ 100 no mês atual
      if current_month_sales > 10000 # R$ 100 em centavos
        current_month_work_days = calculate_seller_work_days_in_month(data[:seller], Date.current)
        seller_potential = best_average_per_day * current_month_work_days
        total_potential += seller_potential
        active_sellers_with_sales += 1
      end
    end
    
    # Garantir que o potencial nunca seja menor que as vendas atuais
    current_month_sales = store.orders
                               .joins(:order_items)
                               .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                      Date.current.beginning_of_month, Date.current.end_of_day)
                               .sum('order_items.quantity * order_items.unit_price')
    
    # Se o potencial calculado for menor que as vendas atuais, usar as vendas atuais como base
    final_potential = [total_potential, current_month_sales].max
    
    {
      potential: final_potential.round(2),
      best_seller_average: best_seller_data[:average_per_day].round(2),
      total_work_days: seller_averages.sum { |data| calculate_seller_work_days_in_month(data[:seller], Date.current) },
      best_seller: {
        id: best_seller_data[:seller].id,
        name: best_seller_data[:seller].name,
        average_per_day: best_seller_data[:average_per_day].round(2),
        total_sales: best_seller_data[:total_sales].round(2),
        days_worked: best_seller_data[:days_worked],
        monthly_sales: calculate_seller_monthly_sales(best_seller_data[:seller], Date.current)
      }
    }
  end

  def calculate_total_returns_value(store)
    # Calcular valor total das devoluções da loja
    # Como as devoluções não têm ligação direta com vendas, vamos estimar com base no preço médio
    returns = Return.where(store_id: store.id)
    
    # Se não há devoluções, retornar 0
    return 0 if returns.empty?
    
    # Calcular preço médio dos produtos da loja para estimar valor das devoluções
    average_price = store.orders.joins(:order_items).average('order_items.unit_price') || 0
    
    # Valor estimado das devoluções = quantidade devolvida × preço médio
    returns.sum(:quantity_returned) * average_price
  end
  
  def calculate_period_returns_value(store, start_date, end_date)
    # Calcular valor das devoluções em um período específico
    # Primeiro tentar o join, se falhar, retornar 0
    begin
      returns = Return.where(store_id: store.id)
                      .where('returns.processed_at >= ? AND returns.processed_at <= ?', start_date, end_date)
      
      return 0 if returns.empty?
      
      average_price = store.orders.joins(:order_items).average('order_items.unit_price') || 0
      returns.sum(:quantity_returned) * average_price
    rescue => e
      # Se houver erro no join (devoluções sem original_order), retornar 0
      Rails.logger.warn "Erro ao calcular devoluções: #{e.message}"
      0
    end
  end

  def calculate_monthly_net_sales(store, orders)
    # Calcular vendas líquidas mês a mês para 2025
    monthly_data = {}
    current_year = Date.current.year
    
    # Para cada mês de 2025
    (1..12).each do |month|
      start_date = Date.new(current_year, month, 1)
      end_date = start_date.end_of_month
      
      # Pular meses futuros
      next if start_date > Date.current
      
      # Vendas brutas do mês
      month_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', start_date, end_date)
      gross_sales = calculate_sales_from_orders(month_orders)
      
      # Trocas do mês
      month_exchanges = Exchange.joins(:seller)
        .where(sellers: { store_id: store.id })
        .where('processed_at >= ? AND processed_at <= ?', start_date, end_date)
        .sum(:voucher_value)
      
      # Devoluções do mês
      month_returns = calculate_period_returns_value(store, start_date, end_date)
      
      # Vendas líquidas
      net_sales = gross_sales - month_exchanges - month_returns
      
      month_key = start_date.strftime('%Y-%m')
      monthly_data[month_key] = {
        gross: gross_sales.round(2),
        exchanges: month_exchanges.round(2),
        returns: month_returns.round(2),
        net: net_sales.round(2)
      }
    end
    
    monthly_data
  end

  def calculate_seller_commission(seller, net_sales, store)
    # Buscar meta mais recente do vendedor (ativa ou a última expirada)
    recent_goal = seller.goals.order(end_date: :desc).first
    
    return 0 unless recent_goal && recent_goal.target_value > 0
    
    # Calcular percentual de atingimento baseado na meta mais recente
    achievement_percentage = (recent_goal.current_value / recent_goal.target_value) * 100
    
    # Buscar níveis de comissão da loja, ordenados por achievement_percentage decrescente
    commission_levels = store.commission_levels.where(active: true).order(achievement_percentage: :desc)
    
    return 0 if commission_levels.empty?
    
    # Encontrar o nível de comissão aplicável (o maior achievement_percentage que o vendedor atingiu)
    applicable_level = commission_levels.find { |level| achievement_percentage >= level.achievement_percentage }
    
    return 0 unless applicable_level
    
    # Calcular comissão baseada nas vendas líquidas anuais × percentual de comissão
    commission_value = net_sales * (applicable_level.commission_percentage / 100.0)
    
    commission_value
  end

  def ensure_store_access
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end

  def calculate_seller_work_days_in_month(seller, date)
    # Buscar escalas do vendedor para o mês especificado
    month_start = date.beginning_of_month
    month_end = date.end_of_month
    
    # Buscar dias em que o vendedor está escalado no mês
    scheduled_days = seller.schedules
                           .where(date: month_start..month_end)
                           .count
    
    # Se o vendedor tem escalas definidas, usar o número de dias escalados
    if scheduled_days > 0
      return scheduled_days
    end
    
    # Se não tem escalas definidas, considerar 24 dias como padrão
    # (excluindo domingos e alguns sábados)
    return 24
  end

  def calculate_seller_monthly_sales(seller, date)
    # Calcular vendas do vendedor no mês especificado
    month_start = date.beginning_of_month
    month_end = date.end_of_month
    
    monthly_orders = seller.orders
                          .joins(:order_items)
                          .where('orders.sold_at >= ? AND orders.sold_at <= ?', month_start, month_end)
    
    calculate_sales_from_orders(monthly_orders)
  end

  def calculate_best_seller_week(store, active_sellers)
    # Calcular melhor vendedor da semana atual
    week_start = Date.current.beginning_of_week
    week_end = Date.current.end_of_week
    
    return nil if active_sellers.empty?
    
    # Calcular vendas de cada vendedor na semana atual
    weekly_performance = active_sellers.map do |seller|
      weekly_orders = seller.orders
                           .joins(:order_items)
                           .where('orders.sold_at >= ? AND orders.sold_at <= ?', week_start, week_end)
      
      weekly_sales = calculate_sales_from_orders(weekly_orders)
      
      # Calcular dias trabalhados na semana
      daily_sales = {}
      weekly_orders.each do |order|
        date_key = order.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        # Calcular vendas do pedido individual
        order_sales = order.order_items.sum('quantity * unit_price')
        daily_sales[date_key] += order_sales
      end
      
      days_worked = daily_sales.keys.count
      daily_average = days_worked > 0 ? (weekly_sales.to_f / days_worked) : 0
      
      {
        seller: seller,
        weekly_sales: weekly_sales,
        daily_average: daily_average,
        days_worked: days_worked
      }
    end
    
    # Encontrar o vendedor com melhor performance na semana
    best_performer = weekly_performance.max_by { |data| data[:weekly_sales] }
    
    return nil if best_performer.nil? || best_performer[:weekly_sales] == 0
    
    {
      id: best_performer[:seller].id,
      name: best_performer[:seller].name,
      weekly_sales: best_performer[:weekly_sales].round(2),
      daily_average: best_performer[:daily_average].round(2),
      days_worked: best_performer[:days_worked]
    }
  end

  def calculate_date_range(period)
    case period
    when 'current-month'
      {
        start_date: Date.current.beginning_of_month.beginning_of_day,
        end_date: Date.current.end_of_day
      }
    when 'all-time'
      {
        start_date: 1.year.ago.beginning_of_day,
        end_date: Date.current.end_of_day
      }
    else
      # Para períodos específicos no formato "YYYY-MM"
      if period.match(/^\d{4}-\d{2}$/)
        year, month = period.split('-').map(&:to_i)
        start_date = Date.new(year, month, 1)
        {
          start_date: start_date.beginning_of_day,
          end_date: start_date.end_of_month.end_of_day
        }
      else
        # Fallback para último ano
        {
          start_date: 1.year.ago.beginning_of_day,
          end_date: Date.current.end_of_day
        }
      end
    end
  end
end 