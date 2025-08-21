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
      # Buscar metas individuais dos vendedores da loja + metas por loja (store_wide)
      seller_ids = current_user.store.sellers.pluck(:id)
      @goals = Goal.includes(:seller)
                   .where('seller_id IN (?) OR (seller_id IS NULL AND goal_scope = ?)', 
                          seller_ids, Goal.goal_scopes[:store_wide])
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

    # Calcular progresso automaticamente para todas as metas
    @goals.each do |goal|
      update_goal_progress(goal)
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
      # Calcular progresso inicial da meta
      update_goal_progress(@goal)
      
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
      # Verificar se é meta individual da loja ou meta por loja (store_wide)
      seller_ids = current_user.store.sellers.pluck(:id)
      goal_belongs_to_store = (@goal.seller_id.present? && seller_ids.include?(@goal.seller_id)) ||
                              (@goal.seller_id.nil? && @goal.goal_scope == 'store_wide')
      
      unless goal_belongs_to_store
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
      # Verificar se é meta individual da loja ou meta por loja (store_wide)
      seller_ids = current_user.store.sellers.pluck(:id)
      goal_belongs_to_store = (@goal.seller_id.present? && seller_ids.include?(@goal.seller_id)) ||
                              (@goal.seller_id.nil? && @goal.goal_scope == 'store_wide')
      
      unless goal_belongs_to_store
        render json: { error: 'Meta não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    @goal.destroy
    render json: { message: 'Meta excluída com sucesso' }
  end

  # POST /goals/:id/recalculate_progress
  def recalculate_progress
    @goal = Goal.find(params[:id])
    
    # Verificar se o goal pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      # Verificar se é meta individual da loja ou meta por loja (store_wide)
      seller_ids = current_user.store.sellers.pluck(:id)
      goal_belongs_to_store = (@goal.seller_id.present? && seller_ids.include?(@goal.seller_id)) ||
                              (@goal.seller_id.nil? && @goal.goal_scope == 'store_wide')
      
      unless goal_belongs_to_store
        render json: { error: 'Meta não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end
    
    # Calcular progresso usando método reutilizável
    update_goal_progress(@goal)
    
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

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  def update_goal_progress(goal)
    # Calcular o valor atual das vendas líquidas para esta meta
    if goal.goal_scope == 'individual' && goal.seller_id.present?
      # Meta individual: somar vendas líquidas do vendedor no período da meta
      orders_in_period = Order.where(seller_id: goal.seller_id)
                             .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                    goal.start_date.beginning_of_day, goal.end_date.end_of_day)
      current_sales = orders_in_period.sum(&:net_total)
    else
      # Meta da loja: somar vendas líquidas da loja no período da meta
      # Para meta por loja, sempre usar a loja do usuário atual
      store_id = current_user.store&.id
      if store_id.present?
        orders_in_period = Order.joins(:seller)
                               .where(sellers: { store_id: store_id })
                               .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                      goal.start_date.beginning_of_day, goal.end_date.end_of_day)
        current_sales = orders_in_period.sum(&:net_total)
      else
        current_sales = 0
      end
    end
    
    # Atualizar o current_value da meta
    goal.update_column(:current_value, current_sales || 0)
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
