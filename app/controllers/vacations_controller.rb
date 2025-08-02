class VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vacation, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    @vacations = current_user.store.vacations
                              .includes(:seller)
                              .order(start_date: :desc)
    
    render json: @vacations.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def show
    render json: @vacation.as_json(include: { seller: { only: [:id, :name, :code] } })
  end

  def create
    @vacation = current_user.store.vacations.build(vacation_params)
    
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
    @vacation = current_user.store.vacations.find(params[:id])
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
