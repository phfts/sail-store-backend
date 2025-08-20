class OrderItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order_item, only: [:show, :update, :destroy]

  def index
    @order_items = OrderItem.includes(:order, :product, order: :seller)
    
    if params[:order_id]
      @order_items = @order_items.where(order_id: params[:order_id])
    end
    
    if params[:store_id]
      @order_items = @order_items.joins(order: :seller).where(sellers: { store_id: params[:store_id] })
    end
    
    render json: @order_items.as_json(
      include: { 
        order: { 
          only: [:id, :external_id],
          include: { seller: { only: [:id, :name, :display_name] } }
        },
        product: { only: [:id, :name, :external_id] }
      },
      methods: [:subtotal]
    )
  end

  # Carrega itens de pedido sem duplicatas baseado em order_id e product_id
  def load_order_items
    order_items_data = params[:order_items] || []
    
    if order_items_data.empty?
      render json: { error: "Lista de order_items é obrigatória" }, status: :bad_request
      return
    end

    # Extrai os pares order_id e product_id dos dados recebidos
    order_product_pairs = order_items_data.map { |item| [item[:order_id], item[:product_id]] }
    
    # Busca itens existentes
    existing_items = OrderItem.where(order_id: order_items_data.map { |item| item[:order_id] })
                             .where(product_id: order_items_data.map { |item| item[:product_id] })
    
    existing_pairs = existing_items.map { |item| [item.order_id, item.product_id] }
    
    # Filtra apenas os pares que não existem
    new_pairs = order_product_pairs - existing_pairs
    
    render json: {
      existing_order_items: existing_items.as_json(
        include: { 
          order: { 
            only: [:id, :external_id],
            include: { seller: { only: [:id, :name, :display_name] } }
          },
          product: { only: [:id, :name, :external_id] }
        },
        methods: [:subtotal]
      ),
      new_order_items: new_pairs,
      total_existing: existing_items.count,
      total_new: new_pairs.count
    }
  end

  # Carrega itens de pedido em lote usando o serviço
  def bulk_load_order_items
    order_items_data = params[:order_items] || []
    
    if order_items_data.empty?
      render json: { error: "Dados de itens de pedido são obrigatórios" }, status: :bad_request
      return
    end

    service = OrderBulkService.new
    result = service.load_order_items(order_items_data)
    
    if result[:error]
      render json: result, status: :bad_request
    else
      render json: result
    end
  end

  def show
    render json: @order_item.as_json(
      include: { 
        order: { 
          only: [:id, :external_id],
          include: { seller: { only: [:id, :name, :display_name] } }
        },
        product: { only: [:id, :name, :external_id] }
      },
      methods: [:subtotal]
    )
  end

  def create
    @order_item = OrderItem.new(order_item_params)
    
    if @order_item.save
      render json: @order_item.as_json(
        include: { 
          product: { only: [:id, :name, :external_id] },
          order: { 
            only: [:id, :external_id],
            include: { seller: { only: [:id, :name, :display_name] } }
          }
        },
        methods: [:subtotal]
      ), status: :created
    else
      render json: { errors: @order_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @order_item.update(order_item_params)
      render json: @order_item.as_json(
        include: { 
          product: { only: [:id, :name, :external_id] },
          order: { 
            only: [:id, :external_id],
            include: { seller: { only: [:id, :name, :display_name] } }
          }
        },
        methods: [:subtotal]
      )
    else
      render json: { errors: @order_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @order_item.destroy
    render json: { message: "Item do pedido excluído com sucesso" }
  end

  private

  def set_order_item
    @order_item = OrderItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item do pedido não encontrado" }, status: :not_found
  end

  def order_item_params
    params.require(:order_item).permit(:order_id, :product_id, :store_id, :quantity, :unit_price, :external_id)
  end
end
