class ShiftsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shift, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    @shifts = current_user.store.shifts.order(:name)
    render json: @shifts
  end

  def show
    render json: @shift
  end

  def create
    @shift = current_user.store.shifts.build(shift_params)
    
    if @shift.save
      render json: @shift, status: :created
    else
      render json: { errors: @shift.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @shift.update(shift_params)
      render json: @shift
    else
      render json: { errors: @shift.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @shift.schedules.exists?
      render json: { error: "Não é possível excluir um turno que possui escalas associadas" }, status: :unprocessable_entity
    else
      @shift.destroy
      render json: { message: "Turno excluído com sucesso" }
    end
  end

  private

  def set_shift
    @shift = current_user.store.shifts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Turno não encontrado" }, status: :not_found
  end

  def shift_params
    params.require(:shift).permit(:name, :start_time, :end_time)
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
