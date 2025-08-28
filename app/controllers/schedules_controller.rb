class SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    start_date = params[:start_date]&.to_date || Date.current.beginning_of_week
    end_date = params[:end_date]&.to_date || Date.current.end_of_week
    
    if current_user.admin?
      # Admins podem ver todas as escalas
      @schedules = Schedule.joins(:store)
                          .includes(:seller, :shift)
                          .for_date_range(start_date, end_date)
                          .order(:date)
    else
      # Usuários regulares veem apenas as escalas da sua loja
      @schedules = current_user.store.schedules
                              .includes(:seller, :shift)
                              .for_date_range(start_date, end_date)
                              .order(:date)
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

  def bulk_create
    # Determinar a loja
    store = if current_user.admin?
              store_id = params[:store_id] || current_user.store&.id
              Store.find(store_id) if store_id
            else
              current_user.store
            end

    unless store
      render json: { error: "Loja não encontrada" }, status: :unprocessable_entity
      return
    end

    # Validar parâmetros obrigatórios
    seller_id = params[:seller_id]
    shift_id = params[:shift_id]
    dates = params[:dates]

    unless seller_id && shift_id && dates
      render json: { error: "seller_id, shift_id e dates são obrigatórios" }, status: :unprocessable_entity
      return
    end

    # Verificar se o vendedor e turno existem
    seller = store.sellers.find_by(id: seller_id)
    shift = store.shifts.find_by(id: shift_id)

    unless seller
      render json: { error: "Vendedor não encontrado" }, status: :unprocessable_entity
      return
    end

    unless shift
      render json: { error: "Turno não encontrado" }, status: :unprocessable_entity
      return
    end

    # Converter strings de data para objetos Date
    begin
      date_objects = dates.map { |date_str| Date.parse(date_str) }
    rescue ArgumentError => e
      render json: { error: "Formato de data inválido: #{e.message}" }, status: :unprocessable_entity
      return
    end

    # Verificar se já existem escalas para estas datas
    existing_schedules = Schedule.where(
      seller_id: seller_id,
      shift_id: shift_id,
      store_id: store.id,
      date: date_objects
    )

    if existing_schedules.any?
      existing_dates = existing_schedules.pluck(:date).map(&:to_s)
      render json: { 
        error: "Já existem escalas para algumas datas",
        existing_dates: existing_dates
      }, status: :unprocessable_entity
      return
    end

    # Criar as escalas
    created_schedules = []
    failed_schedules = []

    date_objects.each do |date|
      schedule = Schedule.new(
        seller_id: seller_id,
        shift_id: shift_id,
        store_id: store.id,
        date: date
      )

      if schedule.save
        created_schedules << schedule
      else
        failed_schedules << {
          date: date.to_s,
          errors: schedule.errors.full_messages
        }
      end
    end

    # Preparar resposta
    response = {
      message: "Escalas criadas com sucesso",
      created_count: created_schedules.count,
      failed_count: failed_schedules.count
    }

    if created_schedules.any?
      response[:created_schedules] = created_schedules.as_json(
        include: { 
          seller: { only: [:id, :name] }, 
          shift: { only: [:id, :name, :start_time, :end_time] } 
        }
      )
    end

    if failed_schedules.any?
      response[:failed_schedules] = failed_schedules
    end

    # Retornar status apropriado
    if failed_schedules.empty?
      render json: response, status: :created
    elsif created_schedules.empty?
      render json: response, status: :unprocessable_entity
    else
      render json: response, status: :partial_content
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
    params.require(:schedule).permit(:seller_id, :shift_id, :date, :store_id)
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
