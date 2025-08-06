class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update, :destroy]

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
