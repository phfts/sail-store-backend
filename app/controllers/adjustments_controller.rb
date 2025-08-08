class AdjustmentsController < ApplicationController
  before_action :set_store, only: [:index, :create, :stats]
  before_action :set_adjustment, only: [:show, :update, :destroy]
  before_action :require_store_access!, only: [:index, :create, :stats]
  
  # GET /stores/:slug/adjustments
  def index
    @adjustments = @store.adjustments.includes(:seller).recent
    
    # Filtros opcionais
    @adjustments = @adjustments.for_seller(params[:seller_id]) if params[:seller_id].present?
    @adjustments = @adjustments.by_date(Date.parse(params[:date])) if params[:date].present?
    @adjustments = @adjustments.positive if params[:type] == 'credit'
    @adjustments = @adjustments.negative if params[:type] == 'debit'
    
    # Paginação
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    offset = (page - 1) * per_page
    
    @adjustments = @adjustments.limit(per_page).offset(offset)
    
    render json: {
      adjustments: @adjustments.map { |adjustment| adjustment_response(adjustment) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: @store.adjustments.count
      }
    }
  end
  
  # GET /stores/:slug/adjustments/stats
  def stats
    stats = {
      total_adjustments: @store.adjustments.count,
      total_amount: @store.adjustments.sum(:amount),
      total_credits: @store.adjustments.positive.sum(:amount),
      total_debits: @store.adjustments.negative.sum(:amount).abs,
      this_month_total: @store.adjustments.this_month.sum(:amount),
      by_seller: seller_stats
    }
    
    render json: stats
  end
  
  # GET /adjustments/:id
  def show
    render json: adjustment_response(@adjustment)
  end
  
  # POST /stores/:slug/adjustments
  def create
    @adjustment = @store.adjustments.build(adjustment_params)
    
    if @adjustment.save
      render json: adjustment_response(@adjustment), status: :created
    else
      render_validation_errors(@adjustment)
    end
  end
  
  # PUT /adjustments/:id
  def update
    if @adjustment.update(adjustment_params)
      render json: adjustment_response(@adjustment)
    else
      render_validation_errors(@adjustment)
    end
  end
  
  # DELETE /adjustments/:id
  def destroy
    @adjustment.destroy
    render json: { message: 'Ajuste removido com sucesso' }
  end
  
  private
  
  def set_store
    @store = Store.find_by!(slug: params[:slug])
    
    # Verificar se o usuário tem acesso à loja
    unless current_user.admin? || current_user.store_id == @store.id
      render json: { error: "Acesso negado" }, status: :forbidden
      return
    end
  end
  
  def set_adjustment
    @adjustment = current_user.admin? ? 
      Adjustment.find(params[:id]) : 
      current_user.store.adjustments.find(params[:id])
  end
  
  def require_store_access!
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end

  def adjustment_params
    params.require(:adjustment).permit(:seller_id, :amount, :description, :date)
  end

  def adjustment_response(adjustment)
    {
      id: adjustment.id,
      seller_id: adjustment.seller_id,
      seller_name: adjustment.seller.display_name,
      store_id: adjustment.store_id,
      amount: adjustment.amount.to_f,
      formatted_amount: adjustment.formatted_amount,
      formatted_amount_with_sign: adjustment.formatted_amount_with_sign,
      description: adjustment.description,
      adjustment_type: adjustment.adjustment_type,
      positive: adjustment.positive?,
      negative: adjustment.negative?,
      date: adjustment.date,
      created_at: adjustment.created_at,
      updated_at: adjustment.updated_at
    }
  end
  
  def seller_stats
    @store.sellers.select(&:active?).map do |seller|
      {
        seller_id: seller.id,
        seller_name: seller.display_name,
        total_adjustments: seller.adjustments.count,
        total_amount: seller.adjustments.sum(:amount).to_f,
        total_credits: seller.adjustments.positive.sum(:amount).to_f,
        total_debits: seller.adjustments.negative.sum(:amount).abs.to_f
      }
    end
  end
  
  def render_validation_errors(model)
    render json: { 
      error: 'Dados inválidos', 
      errors: model.errors.full_messages 
    }, status: :unprocessable_entity
  end
end