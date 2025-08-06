class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update, :destroy]
  
  # Força o carregamento do serviço
  require_relative '../services/order_bulk_service'

  def index
    @orders = Order.includes(:seller, :order_items => [:product])
    
    if params[:seller_id]
      @orders = @orders.where(seller_id: params[:seller_id])
    end
    
    render json: @orders.as_json(
      include: { 
        seller: { only: [:id, :name, :external_id] },
        order_items: {
          include: { product: { only: [:id, :name, :external_id] } }
        }
      },
      methods: [:total]
    )
  end

  # Carrega pedidos sem duplicatas baseado em external_id
  def load_orders
    external_ids = params[:external_ids] || []
    
    if external_ids.empty?
      render json: { error: "Lista de external_ids é obrigatória" }, status: :bad_request
      return
    end

    # Busca pedidos existentes
    existing_orders = Order.where(external_id: external_ids)
    existing_external_ids = existing_orders.pluck(:external_id)
    
    # Filtra apenas os external_ids que não existem
    new_external_ids = external_ids - existing_external_ids
    
    render json: {
      existing_orders: existing_orders.as_json(
        include: { 
          seller: { only: [:id, :name, :external_id] },
          order_items: {
            include: { product: { only: [:id, :name, :external_id] } }
          }
        },
        methods: [:total]
      ),
      new_external_ids: new_external_ids,
      total_existing: existing_orders.count,
      total_new: new_external_ids.count
    }
  end

  # Carrega pedidos em lote usando o serviço
  def bulk_load_orders
    orders_data = params[:orders] || []
    
    if orders_data.empty?
      render json: { error: "Dados de pedidos são obrigatórios" }, status: :bad_request
      return
    end

    # Usa a mesma lógica que funciona no endpoint normal
    created_orders = []
    errors = []
    
    orders_data.each do |order_data|
      begin
        # Usa order_params para garantir que apenas atributos permitidos sejam usados
        order = Order.new(order_params_from_data(order_data))
        
        if order.save
          created_orders << order
        else
          errors << {
            external_id: order_data[:external_id],
            errors: order.errors.full_messages
          }
        end
      rescue => e
        errors << {
          external_id: order_data[:external_id],
          errors: [e.message]
        }
      end
    end
    
    render json: {
      success: errors.empty?,
      created_orders: created_orders.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total]
      ),
      errors: errors,
      summary: {
        total_created_orders: created_orders.count,
        total_errors: errors.count
      }
    }
  end
  
  private
  
  def order_params_from_data(data)
    # Filtra apenas os parâmetros permitidos
    {
      external_id: data[:external_id],
      seller_id: data[:seller_id],
      sold_at: data[:sold_at]
    }
  end

  # Carrega pedidos com seus itens em uma única operação
  def bulk_load_orders_with_items
    orders_with_items_data = params[:orders_with_items] || []
    
    if orders_with_items_data.empty?
      render json: { error: "Dados de pedidos com itens são obrigatórios" }, status: :bad_request
      return
    end

    service = OrderBulkService.new
    result = service.load_orders_with_items(orders_with_items_data)
    
    if result[:error]
      render json: result, status: :bad_request
    else
      render json: result
    end
  end

  def show
    render json: @order.as_json(
      include: { 
        seller: { only: [:id, :name, :external_id] },
        order_items: {
          include: { product: { only: [:id, :name, :external_id] } }
        }
      },
      methods: [:total]
    )
  end

  def create
    @order = Order.new(order_params)
    
    if @order.save
      render json: @order.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total]
      ), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    @order = Order.new(order_params)
    
    if @order.save
      render json: @order.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total]
      ), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @order.update(order_params)
      render json: @order.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total]
      )
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    render json: { message: "Pedido excluído com sucesso" }
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Pedido não encontrado" }, status: :not_found
  end

  def order_params
    params.require(:order).permit(:external_id, :seller_id, :sold_at, 
      order_items_attributes: [:product_id, :store_id, :quantity, :unit_price])
  end
end
