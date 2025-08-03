class VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vacation, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    if current_user.admin?
      # Admins podem ver todas as férias
      @vacations = Vacation.joins(:seller => :store)
                          .includes(:seller)
                          .order(start_date: :desc)
    else
      # Usuários regulares veem apenas as férias da sua loja
      @vacations = current_user.store.vacations
                              .includes(:seller)
                              .order(start_date: :desc)
    end
    
    render json: @vacations.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def show
    render json: @vacation.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def create
    if current_user.admin?
      # Para admins, precisamos especificar a loja através do seller
      seller_id = params[:seller_id] || Seller.first&.id
      unless seller_id
        render json: { error: "Nenhum vendedor encontrado" }, status: :unprocessable_entity
        return
      end
      @vacation = Seller.find(seller_id).vacations.build(vacation_params)
    else
      @vacation = current_user.store.vacations.build(vacation_params)
    end
    
    if @vacation.save
      render json: @vacation.as_json(include: { seller: { only: [:id, :name, :code] } }), 
             status: :created
    else
      render json: { errors: @vacation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @vacation.update(vacation_params)
      render json: @vacation.as_json(include: { seller: { only: [:id, :name, :code] } })
    else
      render json: { errors: @vacation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @vacation.destroy
    render json: { message: "Férias excluídas com sucesso" }
  end

  private

  def set_vacation
    if current_user.admin?
      @vacation = Vacation.find(params[:id])
    else
      @vacation = current_user.store.vacations.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Férias não encontradas" }, status: :not_found
  end

  def vacation_params
    params.require(:vacation).permit(:seller_id, :start_date, :end_date, :reason)
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
