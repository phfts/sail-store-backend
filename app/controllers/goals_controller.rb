class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: [:show, :update, :destroy]

  def index
    if current_user.admin?
      # Admins podem ver todas as metas
      @goals = Goal.joins(:seller => :store)
                   .includes(:seller)
                   .order(created_at: :desc)
    else
      # Usuários regulares veem apenas as metas da sua loja
      @goals = current_user.store.goals
                           .includes(:seller)
                           .order(created_at: :desc)
    end
    
    # Filtrar por seller_id se especificado
    if params[:seller_id].present?
      @goals = @goals.where(seller_id: params[:seller_id])
    end
    
    # Filtrar por tipo de meta se especificado
    if params[:goal_type].present?
      @goals = @goals.where(goal_type: params[:goal_type])
    end
    
    # Filtrar por status se especificado
    if params[:status].present?
      case params[:status]
      when 'active'
        @goals = @goals.active
      when 'completed'
        @goals = @goals.completed
      when 'in_progress'
        @goals = @goals.in_progress
      when 'overdue'
        @goals = @goals.where('end_date < ? AND current_value < target_value', Date.current)
      end
    end

    render json: @goals.as_json(
      include: { 
        seller: { 
          only: [:id, :name, :code],
          methods: [:display_name]
        } 
      },
      methods: [:progress_percentage, :is_completed?, :is_overdue?, :days_remaining]
    )
  end

  def show
    render json: @goal.as_json(
      include: { 
        seller: { 
          only: [:id, :name, :code],
          methods: [:display_name]
        } 
      },
      methods: [:progress_percentage, :is_completed?, :is_overdue?, :days_remaining]
    )
  end

  def create
    @goal = Goal.new(goal_params)
    
    # Verificar se o seller pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      seller = current_user.store.sellers.find_by(id: @goal.seller_id)
      unless seller
        render json: { error: 'Vendedor não encontrado ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    if @goal.save
      render json: @goal.as_json(
        include: { 
          seller: { 
            only: [:id, :name, :code],
            methods: [:display_name]
          } 
        },
        methods: [:progress_percentage, :is_completed?, :is_overdue?, :days_remaining]
      ), status: :created
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    # Verificar se o goal pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      unless current_user.store.goals.exists?(@goal.id)
        render json: { error: 'Meta não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    if @goal.update(goal_params)
      render json: @goal.as_json(
        include: { 
          seller: { 
            only: [:id, :name, :code],
            methods: [:display_name]
          } 
        },
        methods: [:progress_percentage, :is_completed?, :is_overdue?, :days_remaining]
      )
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # Verificar se o goal pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      unless current_user.store.goals.exists?(@goal.id)
        render json: { error: 'Meta não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    @goal.destroy
    render json: { message: 'Meta excluída com sucesso' }
  end

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(
      :seller_id, 
      :goal_type, 
      :start_date, 
      :end_date, 
      :target_value, 
      :current_value, 
      :description
    )
  end
end
