class SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    week_number = params[:week_number]&.to_i || Date.current.cweek
    year = params[:year]&.to_i || Date.current.year
    
    @schedules = current_user.store.schedules
                              .includes(:seller, :shift)
                              .for_week(week_number, year)
                              .order(:day_of_week)
    
    render json: @schedules.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                               shift: { only: [:id, :name, :start_time, :end_time] } })
  end

  def show
    render json: @schedule.as_json(include: { seller: { only: [:id, :name, :code] }, 
                                             shift: { only: [:id, :name, :start_time, :end_time] } })
  end

  def create
    @schedule = current_user.store.schedules.build(schedule_params)
    
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
    @schedule = current_user.store.schedules.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Escala não encontrada" }, status: :not_found
  end

  def schedule_params
    params.require(:schedule).permit(:seller_id, :shift_id, :day_of_week, :week_number, :year)
  end

  def ensure_store_access
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
end
