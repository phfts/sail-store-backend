class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: [:show, :update, :destroy]

  def index
    if current_user.admin?
      # Admins podem ver todas as metas
      @goals = Goal.includes(:seller)
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
    
    # Verificar se o seller pertence à loja do usuário (se não for admin e se for meta individual)
    unless current_user.admin?
      if @goal.goal_scope == 'individual' && @goal.seller_id.present?
        seller = current_user.store.sellers.find_by(id: @goal.seller_id)
        unless seller
          render json: { error: 'Vendedor não encontrado ou não pertence à sua loja' }, status: :not_found
          return
        end
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
      render_validation_errors(@goal)
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
      render_validation_errors(@goal)
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
      :goal_scope,
      :start_date, 
      :end_date, 
      :target_value, 
      :current_value, 
      :description
    ).tap do |permitted_params|
      # Se for meta por loja, remover seller_id
      if permitted_params[:goal_scope] == 'store_wide'
        permitted_params[:seller_id] = nil
      end
    end
  end
end
