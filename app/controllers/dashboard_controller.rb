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

    # Buscar vendas reais
    sales = store.sales.includes(:seller)
    current_month_sales = sales.where('sold_at >= ? AND sold_at <= ?', 
      Date.current.beginning_of_month, Date.current.end_of_month)
    
    # Calcular vendas totais do mês atual
    current_sales = current_month_sales.sum(:value)
    
    # Buscar vendas da semana atual
    current_week_sales = sales.where('sold_at >= ? AND sold_at <= ?', 
      Date.current.beginning_of_week, Date.current.end_of_week)
    current_week_total = current_week_sales.sum(:value)
    
    # Buscar vendas de hoje
    today_sales = sales.where('sold_at >= ? AND sold_at <= ?', 
      Date.current.beginning_of_day, Date.current.end_of_day)
    today_total = today_sales.sum(:value)
    
    # Buscar metas ativas
    current_goals = store.goals.where('end_date >= ?', Date.current)
    current_target = current_goals.sum(:target_value)
    
    # Calcular progresso baseado nas vendas reais
    progress = current_target > 0 ? ((current_sales.to_f / current_target) * 100).round(2) : 0

    # Top vendedores baseado em vendas reais
    top_sellers = active_sellers.map do |seller|
      seller_sales = sales.where(seller: seller)
        .where('sold_at >= ? AND sold_at <= ?', 
          Date.current.beginning_of_month, Date.current.end_of_month)
        .sum(:value)
      
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
        total: sales.count,
        currentMonth: current_sales,
        currentWeek: current_week_total,
        today: today_total,
        averagePerDay: current_month_sales.count > 0 ? (current_sales / Date.current.day).round(2) : 0
      },
      targets: {
        current: current_sales,
        target: current_target,
        progress: progress,
        period: "mensal",
        endDate: Date.current.end_of_month.strftime("%d/%m/%Y")
      },
      topSellers: top_sellers
    }
  end

  private

  def ensure_store_access
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
end 