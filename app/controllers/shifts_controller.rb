class ShiftsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store
  before_action :set_shift, only: [:show, :update, :destroy]
  before_action :ensure_store_access

  def index
    # Sempre mostrar apenas os turnos da loja específica
    @shifts = @store.shifts.order(:name)
    render json: @shifts
  end

  def show
    render json: @shift
  end

  def create
    @shift = @store.shifts.build(shift_params)
    
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
    # Permitir exclusão com cascade delete das schedules associadas
    @shift.destroy
    render json: { message: "Turno e todas as escalas associadas foram excluídos com sucesso" }
  end

  private

  def set_store
    if params[:store_slug]
      # Se temos um slug da loja, usar ele
      @store = Store.find_by!(slug: params[:store_slug])
      
      # Verificar acesso à loja específica
      unless current_user.admin? || (current_user.store&.id == @store.id)
        render json: { error: "Acesso negado a esta loja" }, status: :forbidden
        return
      end
    elsif params[:store_id]
      # Se temos um ID da loja, usar ele (para compatibilidade)
      @store = Store.find(params[:store_id])
      
      # Verificar acesso à loja específica
      unless current_user.admin? || (current_user.store&.id == @store.id)
        render json: { error: "Acesso negado a esta loja" }, status: :forbidden
        return
      end
    elsif current_user.admin?
      # Para admins sem loja específica, usar a primeira loja ou erro
      if params[:id] && (shift = Shift.find_by(id: params[:id]))
        @store = shift.store
      else
        render json: { error: "store_slug ou store_id é obrigatório" }, status: :bad_request
        return
      end
    else
      # Para usuários regulares, usar a loja do usuário
      @store = current_user.store
      unless @store
        render json: { error: "Usuário não tem loja associada" }, status: :forbidden
        return
      end
    end
  end

  def set_shift
    @shift = @store.shifts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Turno não encontrado" }, status: :not_found
  end

  def shift_params
    params.require(:shift).permit(:name, :start_time, :end_time)
  end

  def ensure_store_access
    # Verificação já feita em set_store
  end
end
