class AbsencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_absence, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    if current_user.admin?
      @absences = Absence.joins(:seller => :store)
                         .includes(:seller)
                         .order(start_date: :desc)
    else
      @absences = current_user.store.absences
                             .includes(:seller)
                             .order(start_date: :desc)
    end
    
    # Filtrar por seller_id se especificado
    if params[:seller_id].present?
      @absences = @absences.where(seller_id: params[:seller_id])
    end

    # Filtrar por tipo se especificado
    if params[:absence_type].present?
      @absences = @absences.by_type(params[:absence_type])
    end
    
    render json: @absences.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def show
    render json: @absence.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def create
    if current_user.admin?
      seller_id = params[:seller_id] || Seller.first&.id
      unless seller_id
        render json: { error: "Nenhum vendedor encontrado" }, status: :unprocessable_entity
        return
      end
      @absence = Seller.find(seller_id).absences.build(absence_params)
    else
      @absence = current_user.store.absences.build(absence_params)
    end
    
    if @absence.save
      render json: @absence.as_json(include: { seller: { only: [:id, :name, :code] } }), 
             status: :created
    else
      render json: { errors: @absence.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def bulk_create
    # Determinar a loja
    store = if current_user.admin?
              seller_id = params[:seller_id]
              if seller_id
                seller = Seller.find_by(id: seller_id)
                seller&.store
              else
                current_user.store
              end
            else
              current_user.store
            end

    unless store
      render json: { error: "Loja não encontrada" }, status: :unprocessable_entity
      return
    end

    # Validar parâmetros obrigatórios
    seller_id = params[:seller_id]
    dates = params[:dates]
    reason = params[:reason]
    absence_type = params[:absence_type] || 'vacation'

    unless seller_id && dates
      render json: { error: "seller_id e dates são obrigatórios" }, status: :unprocessable_entity
      return
    end

    # Verificar se o vendedor existe
    seller = store.sellers.find_by(id: seller_id)
    unless seller
      render json: { error: "Vendedor não encontrado" }, status: :unprocessable_entity
      return
    end

    # Converter strings de data para objetos Date
    begin
      date_objects = dates.map { |date_str| Date.parse(date_str) }
    rescue ArgumentError => e
      render json: { error: "Formato de data inválido: #{e.message}" }, status: :unprocessable_entity
      return
    end

    # Ordenar as datas
    date_objects.sort!

    # Agrupar datas consecutivas em períodos
    periods = []
    current_period = { start_date: date_objects.first, end_date: date_objects.first }

    date_objects[1..-1].each do |date|
      if date == current_period[:end_date] + 1.day
        # Data consecutiva, estender o período
        current_period[:end_date] = date
      else
        # Quebra na sequência, salvar período atual e iniciar novo
        periods << current_period
        current_period = { start_date: date, end_date: date }
      end
    end
    periods << current_period

    # Verificar se já existem ausências para estas datas
    existing_absences = Absence.where(seller_id: seller_id)
                              .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
                                     date_objects.last, date_objects.first,
                                     date_objects.first, date_objects.first,
                                     date_objects.first, date_objects.last)

    if existing_absences.any?
      render json: { 
        error: "Já existem ausências para algumas datas",
        existing_absences: existing_absences.as_json(only: [:start_date, :end_date, :reason])
      }, status: :unprocessable_entity
      return
    end

    # Criar as ausências
    created_absences = []
    failed_absences = []

    periods.each do |period|
      absence = Absence.new(
        seller_id: seller_id,
        start_date: period[:start_date],
        end_date: period[:end_date],
        reason: reason,
        absence_type: absence_type
      )

      if absence.save
        created_absences << absence
      else
        failed_absences << {
          start_date: period[:start_date].to_s,
          end_date: period[:end_date].to_s,
          errors: absence.errors.full_messages
        }
      end
    end

    # Preparar resposta
    response = {
      message: "Ausências criadas com sucesso",
      created_count: created_absences.count,
      failed_count: failed_absences.count,
      periods_created: periods.count
    }

    if created_absences.any?
      response[:created_absences] = created_absences.as_json(
        include: { seller: { only: [:id, :name] } }
      )
    end

    if failed_absences.any?
      response[:failed_absences] = failed_absences
    end

    # Retornar status apropriado
    if failed_absences.empty?
      render json: response, status: :created
    elsif created_absences.empty?
      render json: response, status: :unprocessable_entity
    else
      render json: response, status: :partial_content
    end
  end

  def update
    if @absence.update(absence_params)
      render json: @absence.as_json(include: { seller: { only: [:id, :name, :code] } })
    else
      render json: { errors: @absence.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @absence.destroy
    render json: { message: "Ausência excluída com sucesso" }
  end

  # Nova rota para buscar ausência atual de um vendedor
  def current
    seller_id = params[:seller_id]
    unless seller_id
      render json: { error: "seller_id é obrigatório" }, status: :bad_request
      return
    end

    current_absence = Absence.current.for_seller(seller_id).first
    
    if current_absence
      render json: current_absence.as_json(include: { seller: { only: [:id, :name, :code] } })
    else
      render json: { absence: nil }
    end
  end

  private

  def set_absence
    if current_user.admin?
      @absence = Absence.find(params[:id])
    else
      @absence = current_user.store.absences.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Ausência não encontrada" }, status: :not_found
  end

  def absence_params
    params.require(:absence).permit(:seller_id, :start_date, :end_date, :absence_type, :reason, :description)
  end

  def ensure_store_access
    return if current_user.admin?
    
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
end
