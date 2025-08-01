class MetricsController < ApplicationController
  before_action :require_admin!

  def index
    metrics = {
      total_stores: Store.count,
      total_users: User.count,
      monthly_active_users: calculate_monthly_active_users,
      weekly_active_users: calculate_weekly_active_users,
      daily_active_users: calculate_daily_active_users
    }

    render json: metrics
  end

  private

  def calculate_monthly_active_users
    # Usuários únicos que fizeram login no último mês
    LoginLog.unique_users_in_period(:month)
  end

  def calculate_weekly_active_users
    # Usuários únicos que fizeram login na última semana
    LoginLog.unique_users_in_period(:week)
  end

  def calculate_daily_active_users
    # Usuários únicos que fizeram login hoje
    LoginLog.unique_users_in_period(:day)
  end
end
