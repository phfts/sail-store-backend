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
    sellers_on_vacation = sellers.joins(:vacations)
      .where('vacations.start_date <= ? AND vacations.end_date >= ?', Date.current, Date.current)
      .distinct

    # Buscar turnos
    shifts = store.shifts
    active_shifts = shifts

    # Buscar escalas
    schedules = store.schedules
    current_week = Date.current.cweek
    current_year = Date.current.year
    next_schedule = schedules.where('week_number >= ? AND year >= ?', current_week, current_year)
      .order(:week_number, :year)
      .first

    # Buscar férias
    vacations = store.vacations
    active_vacations = vacations.where('start_date <= ? AND end_date >= ?', Date.current, Date.current)

    # Buscar metas (mock por enquanto)
    current_target = 15000
    current_sales = 8750
    progress = ((current_sales.to_f / current_target) * 100).round(2)

    # Top vendedores (mock por enquanto)
    top_sellers = active_sellers.first(3).map do |seller|
      {
        id: seller.id,
        name: seller.name,
        sales: rand(2000..5000), # Mock data
        avatar: nil
      }
    end

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
        nextSchedule: next_schedule ? {
          startDate: "Semana #{next_schedule.week_number}",
          endDate: "#{next_schedule.year}",
          sellersCount: schedules.where(week_number: next_schedule.week_number, year: next_schedule.year).count
        } : nil
      },
      vacations: {
        total: vacations.count,
        active: active_vacations.count
      },
      targets: {
        current: current_sales,
        target: current_target,
        progress: progress,
        period: "semanal",
        endDate: "15/04/2025"
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