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
    
    # Vendas do mês atual
    current_month_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_month, Date.current.end_of_month)
    current_month_sales = calculate_sales_from_orders(current_month_orders)
    
    # Vendas da semana atual
    current_week_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_week, Date.current.end_of_week)
    current_week_sales = calculate_sales_from_orders(current_week_orders)
    
    # Vendas de hoje
    today_orders = orders.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
      Date.current.beginning_of_day, Date.current.end_of_day)
    today_sales = calculate_sales_from_orders(today_orders)
    
    # Total de vendas (todos os pedidos)
    total_sales = calculate_sales_from_orders(orders)
    
    # Buscar metas ativas
    current_goals = store.goals.where('end_date >= ?', Date.current)
    current_target = current_goals.sum(:target_value)
    
    # Calcular progresso baseado nas vendas reais
    progress = current_target > 0 ? ((current_month_sales.to_f / current_target) * 100).round(2) : 0

    # Top vendedores baseado em vendas reais
    top_sellers = active_sellers.map do |seller|
      seller_orders = orders.where(seller: seller)
        .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
          Date.current.beginning_of_month, Date.current.end_of_month)
      seller_sales = calculate_sales_from_orders(seller_orders)
      
      {
        id: seller.id,
        name: seller.name,
        sales: seller_sales,
        avatar: nil
      }
    end.sort_by { |seller| -seller[:sales] }.first(3)

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
        averagePerDay: current_month_orders.count > 0 ? (current_month_sales / Date.current.day).round(2) : 0
      },
      targets: {
        current: current_month_sales,
        target: current_target,
        progress: progress,
        period: "mensal",
        endDate: Date.current.end_of_month.strftime("%d/%m/%Y")
      },
      topSellers: top_sellers
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

  def ensure_store_access
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
end 