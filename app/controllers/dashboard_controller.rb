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
    
    # Calcular progresso baseado nas vendas reais
    progress = current_target > 0 ? ((current_month_sales.to_f / current_target) * 100).round(2) : 0

    # Calcular a melhor média de vendas por dia da loja para usar no potencial individual
    best_average_per_day = 0
    active_sellers.each do |seller|
      seller_orders = orders.where(seller: seller)
        .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
          1.year.ago.beginning_of_day, Date.current.end_of_day)
      
      daily_sales = {}
      seller_orders.each do |order|
        date_key = order.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        daily_sales[date_key] += calculate_sales_from_orders([order])
      end
      
      days_worked = daily_sales.keys.count
      average_per_day = days_worked > 0 ? (calculate_sales_from_orders(seller_orders).to_f / days_worked) : 0
      
      if average_per_day > best_average_per_day
        best_average_per_day = average_per_day
      end
    end

    # Dados anuais de todos os vendedores ativos
    sellers_annual_data = active_sellers.map do |seller|
      seller_orders = orders.where(seller: seller)
        .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
          1.year.ago.beginning_of_day, Date.current.end_of_day)
      
      seller_sales = calculate_sales_from_orders(seller_orders)
      seller_metrics = calculate_metrics(seller_orders)
      
      # Calcular devoluções do vendedor no último ano
      # Como as devoluções não estão linkadas às vendas por external_id,
      # vamos calcular uma distribuição proporcional baseada nas vendas do vendedor
      seller_sales_percentage = seller_orders.count > 0 ? (seller_orders.count.to_f / orders.count) : 0
      
      # Total de devoluções da loja
      total_store_returns = Return.joins(original_order: :seller).where(sellers: { store_id: store.id }).distinct
      
      # Distribuir proporcionalmente as devoluções baseado na participação do vendedor nas vendas
      # Como o return_value não funciona sem vendas associadas, vamos usar uma estimativa
      # baseada na quantidade devolvida e um preço médio dos produtos
      average_product_price = seller_orders.joins(:order_items).average('order_items.unit_price') || 0
      estimated_return_value = total_store_returns.sum(:quantity_returned) * average_product_price
      
      total_returns_value = (estimated_return_value * seller_sales_percentage).round(2)
      total_returns_count = (total_store_returns.count * seller_sales_percentage).round(0)
      
      # Calcular trocas do vendedor (distribuição proporcional)
      total_store_exchanges = Exchange.joins(:seller).where(sellers: { store_id: store.id })
      estimated_exchange_value = total_store_exchanges.sum(:voucher_value) * seller_sales_percentage
      
      # Total de trocas/devoluções = valor perdido pela loja
      total_returns_exchanges_value = total_returns_value + estimated_exchange_value.round(2)
      total_returns_exchanges_count = total_returns_count + (total_store_exchanges.count * seller_sales_percentage).round(0)
      
      # Vendas líquidas = Vendas brutas - Trocas/Devoluções
      net_sales = seller_sales - total_returns_exchanges_value
      
      # Calcular potencial individual (melhor média de vendas por dia × dias trabalhados)
      daily_sales = {}
      seller_orders.each do |order|
        date_key = order.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        daily_sales[date_key] += calculate_sales_from_orders([order])
      end
      
      days_worked = daily_sales.keys.count
      average_per_day = days_worked > 0 ? (seller_sales.to_f / days_worked) : 0
      individual_potential = best_average_per_day * days_worked
      
      {
        id: seller.id,
        name: seller.name,
        sales: seller_sales,
        net_sales: net_sales.round(2),
        potential: individual_potential.round(2),
        ticket_medio: seller_metrics[:ticket_medio],
        produtos_por_atendimento: seller_metrics[:produtos_por_atendimento],
        days_worked: days_worked,
        average_per_day: average_per_day.round(2),
        average_orders_per_day: days_worked > 0 ? (seller_orders.count.to_f / days_worked).round(2) : 0,
        returns_exchanges_value: total_returns_exchanges_value.round(2),
        returns_exchanges_count: total_returns_exchanges_count,
        avatar: nil
      }
    end.sort_by { |seller| -seller[:sales] }

    # Top vendedores (primeiros 3)
    top_sellers = sellers_annual_data.first(3)

    # Calcular Potencial de Vendas
    potencial_vendas = calculate_sales_potential(store, orders, active_sellers)

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
      metrics: {
        ticketMedio: {
          total: total_metrics[:ticket_medio],
          currentMonth: current_month_metrics[:ticket_medio],
          currentWeek: current_week_metrics[:ticket_medio],
          today: today_metrics[:ticket_medio]
        },
        produtosPorAtendimento: {
          total: total_metrics[:produtos_por_atendimento],
          currentMonth: current_month_metrics[:produtos_por_atendimento],
          currentWeek: current_week_metrics[:produtos_por_atendimento],
          today: today_metrics[:produtos_por_atendimento]
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
        bestSeller: potencial_vendas[:best_seller]
      },
      topSellers: top_sellers,
      sellersAnnualData: sellers_annual_data
    }
  end

  private

  def calculate_sales_from_orders(orders)
    total = 0
    orders.each do |order|
      order.order_items.each do |item|
        total += item.quantity * item.unit_price
      end
    end
    total
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
    
    # Calcular quantidade total de itens
    total_items = 0
    orders.each do |order|
      order.order_items.each do |item|
        total_items += item.quantity
      end
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

  def calculate_sales_potential(store, orders, active_sellers)
    return {
      potential: 0.0,
      best_seller_average: 0.0,
      total_work_days: 0,
      best_seller: nil
    } if active_sellers.empty?

    # Calcular média de vendas por dia para cada vendedor ativo
    seller_averages = active_sellers.map do |seller|
      seller_orders = orders.where(seller: seller)
      
      # Calcular vendas por dia para este vendedor
      daily_sales = {}
      seller_orders.each do |order|
        date_key = order.sold_at.to_date.to_s
        daily_sales[date_key] ||= 0
        daily_sales[date_key] += calculate_sales_from_orders([order])
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

    # Encontrar o vendedor com melhor média de vendas por dia
    best_seller_data = seller_averages.max_by { |data| data[:average_per_day] }
    
    return {
      potential: 0.0,
      best_seller_average: 0.0,
      total_work_days: 0,
      best_seller: nil
    } if best_seller_data.nil? || best_seller_data[:average_per_day] == 0

    # A melhor média de vendas por dia da loja é a do melhor vendedor
    best_average_per_day = best_seller_data[:average_per_day]
    
    # Calcular potencial: melhor média de vendas por dia × dias trabalhados de cada vendedor
    total_potential = 0
    seller_averages.each do |data|
      # Potencial deste vendedor = melhor média de vendas por dia × dias trabalhados do vendedor
      seller_potential = best_average_per_day * data[:days_worked]
      total_potential += seller_potential
    end
    
    {
      potential: total_potential.round(2),
      best_seller_average: best_seller_data[:average_per_day].round(2),
      total_work_days: seller_averages.sum { |data| data[:days_worked] },
      best_seller: {
        id: best_seller_data[:seller].id,
        name: best_seller_data[:seller].name,
        average_per_day: best_seller_data[:average_per_day].round(2),
        total_sales: best_seller_data[:total_sales].round(2),
        days_worked: best_seller_data[:days_worked]
      }
    }
  end

  def calculate_total_returns_value(store)
    # Calcular valor total das devoluções da loja
    # Como as devoluções não têm ligação direta com vendas, vamos estimar com base no preço médio
    returns = Return.joins(original_order: :seller).where(sellers: { store_id: store.id })
    
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
      returns = Return.joins(original_order: :seller)
                      .where(sellers: { store_id: store.id })
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

  def ensure_store_access
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
end 