class QueueController < ApplicationController
  before_action :set_store, only: [:index, :create, :stats, :next_customer, :auto_assign]
  before_action :set_queue_item, only: [:show, :update, :destroy, :assign, :complete, :cancel]
  before_action :require_store_access!, only: [:index, :create, :stats, :next_customer, :auto_assign]
  
  # GET /stores/:slug/queue
  def index
    @queue_items = @store.company.queue_items
                         .for_store(@store.id)
                         .includes(:seller, :store, :company)
                         .order(created_at: :desc)
    
    # Filtros opcionais
    @queue_items = @queue_items.where(status: params[:status]) if params[:status].present?
    @queue_items = @queue_items.where(seller_id: params[:seller_id]) if params[:seller_id].present?
    @queue_items = @queue_items.where(priority: params[:priority]) if params[:priority].present?
    
    render json: @queue_items.map { |item| queue_item_response(item) }
  end
  
  # GET /stores/:slug/queue/stats
  def stats
    stats = QueueItem.stats_for_store(@store.id)
    render json: stats
  end
  
  # GET /queue/:id
  def show
    render json: queue_item_response(@queue_item)
  end
  
  # POST /stores/:slug/queue
  def create
    @queue_item = @store.company.queue_items.build(queue_item_params)
    @queue_item.store = @store
    
    if @queue_item.save
      render json: queue_item_response(@queue_item), status: :created
    else
      render_validation_errors(@queue_item)
    end
  end
  
  # PUT /queue/:id
  def update
    if @queue_item.update(queue_item_params)
      render json: queue_item_response(@queue_item)
    else
      render_validation_errors(@queue_item)
    end
  end
  
  # DELETE /queue/:id
  def destroy
    @queue_item.destroy
    render json: { message: 'Item removido da fila com sucesso' }
  end
  
  # PUT /queue/:id/assign
  def assign
    seller_id = params[:seller_id]
    
    if seller_id.blank?
      render json: { error: 'seller_id é obrigatório' }, status: :unprocessable_entity
      return
    end
    
    seller = @queue_item.store.sellers.find_by(id: seller_id)
    
    if seller.nil?
      render json: { error: 'Vendedor não encontrado' }, status: :not_found
      return
    end
    
    unless seller.store_id == @queue_item.store_id
      render json: { error: 'Vendedor não pertence à mesma loja' }, status: :unprocessable_entity
      return
    end
    
    begin
      @queue_item.assign_to_seller!(seller)
      render json: { 
        message: 'Cliente atribuído ao vendedor com sucesso',
        queue_item: queue_item_response(@queue_item) 
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      render json: { error: 'Erro ao atribuir cliente ao vendedor' }, status: :unprocessable_entity
    end
  end
  
  # PUT /queue/:id/complete
  def complete
    begin
      @queue_item.complete!
      render json: { 
        message: 'Atendimento finalizado com sucesso',
        queue_item: queue_item_response(@queue_item) 
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      render json: { error: 'Erro ao finalizar atendimento' }, status: :unprocessable_entity
    end
  end
  
  # PUT /queue/:id/cancel
  def cancel
    begin
      @queue_item.cancel!
      render json: { 
        message: 'Atendimento cancelado com sucesso',
        queue_item: queue_item_response(@queue_item) 
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      render json: { error: 'Erro ao cancelar atendimento' }, status: :unprocessable_entity
    end
  end
  
  # GET /stores/:slug/queue/next
  def next_customer
    next_item = QueueItem.next_in_queue(@store.id)
    
    if next_item
      render json: queue_item_response(next_item)
    else
      render json: { message: 'Nenhum cliente na fila' }, status: :not_found
    end
  end
  
  # POST /stores/:slug/queue/auto_assign
  def auto_assign
    seller_id = params[:seller_id]
    
    if seller_id.blank?
      render json: { error: 'seller_id é obrigatório' }, status: :unprocessable_entity
      return
    end
    
    seller = @store.sellers.find_by(id: seller_id)
    
    if seller.nil?
      render json: { error: 'Vendedor não encontrado' }, status: :not_found
      return
    end
    
    next_item = QueueItem.next_in_queue(@store.id)
    
    if next_item.nil?
      render json: { error: 'Nenhum cliente na fila' }, status: :not_found
      return
    end
    
    begin
      next_item.assign_to_seller!(seller)
      render json: { 
        message: 'Próximo cliente atribuído automaticamente',
        queue_item: queue_item_response(next_item) 
      }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      render json: { error: 'Erro na atribuição automática' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_store
    if current_user.admin?
      @store = Store.find_by!(slug: params[:slug])
    else
      @store = current_user.store
      unless @store&.slug == params[:slug]
        render json: { error: "Acesso negado" }, status: :forbidden
        return
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Loja não encontrada" }, status: :not_found
  end
  
  def set_queue_item
    if current_user.admin?
      @queue_item = QueueItem.find(params[:id])
    else
      # Usuários regulares só podem acessar itens da sua loja
      @queue_item = current_user.store.queue_items.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item da fila não encontrado" }, status: :not_found
  end
  
  def require_store_access!
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end
  
  def queue_item_params
    params.require(:queue_item).permit(:priority, :notes)
  end
  
  def queue_item_response(queue_item)
    {
      id: queue_item.id,
      seller_id: queue_item.seller_id,
      store_id: queue_item.store_id,
      company_id: queue_item.company_id,
      status: queue_item.status,
      priority: queue_item.priority,
      notes: queue_item.notes,
      started_at: queue_item.started_at,
      completed_at: queue_item.completed_at,
      created_at: queue_item.created_at,
      updated_at: queue_item.updated_at,
      seller: queue_item.seller ? {
        id: queue_item.seller.id,
        name: queue_item.seller.name,
        display_name: queue_item.seller.display_name
      } : nil,
      store: {
        id: queue_item.store.id,
        name: queue_item.store.name,
        slug: queue_item.store.slug
      },
      # Campos computados
      status_label: queue_item.status_label,
      priority_label: queue_item.priority_label,
      wait_time: queue_item.wait_time&.to_i,
      service_time: queue_item.service_time&.to_i,
      total_time: queue_item.total_time&.to_i
    }
  end
end