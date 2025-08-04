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
