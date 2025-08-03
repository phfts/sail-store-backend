class SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    week_number = params[:week_number]&.to_i || Date.current.cweek
    year = params[:year]&.to_i || Date.current.year
    
    if current_user.admin?
      # Admins podem ver todas as escalas
      @schedules = Schedule.joins(:store)
                          .includes(:seller, :shift)
                          .for_week(week_number, year)
                          .order(:day_of_week)
    else
      # Usuários regulares veem apenas as escalas da sua loja
      @schedules = current_user.store.schedules
                              .includes(:seller, :shift)
                              .for_week(week_number, year)
                              .order(:day_of_week)
    end
    
    render json: @schedules.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                               shift: { only: [:id, :name, :start_time, :end_time] } })
  end

  def show
    render json: @schedule.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                             shift: { only: [:id, :name, :start_time, :end_time] } })
  end

  def create
    if current_user.admin?
      # Para admins, precisamos especificar a loja
      store_id = params[:store_id] || Store.first&.id
      unless store_id
        render json: { error: "Nenhuma loja encontrada" }, status: :unprocessable_entity
        return
      end
      @schedule = Store.find(store_id).schedules.build(schedule_params)
    else
      @schedule = current_user.store.schedules.build(schedule_params)
    end
    
    if @schedule.save
      render json: @schedule.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                               shift: { only: [:id, :name, :start_time, :end_time] } }), 
             status: :created
    else
      render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @schedule.update(schedule_params)
      render json: @schedule.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                               shift: { only: [:id, :name, :start_time, :end_time] } })
    else
      render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule.destroy
    render json: { message: "Escala excluída com sucesso" }
  end

  private

  def set_schedule
    if current_user.admin?
      @schedule = Schedule.find(params[:id])
    else
      @schedule = current_user.store.schedules.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Escala não encontrada" }, status: :not_found
  end

  def schedule_params
    params.require(:schedule).permit(:seller_id, :shift_id, :day_of_week, :week_number, :year, :store_id)
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
