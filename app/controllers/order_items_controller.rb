class OrderItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order_item, only: [:show, :update, :destroy]

  def index
    @order_items = OrderItem.includes(:order, :product)
    
    if params[:order_id]
      @order_items = @order_items.where(order_id: params[:order_id])
    end
    
    render json: @order_items.as_json(
      include: { 
        order: { only: [:id, :external_id] },
        product: { only: [:id, :name, :external_id] }
      },
      methods: [:subtotal]
    )
  end

  def show
    render json: @order_item.as_json(
      include: { 
        order: { only: [:id, :external_id] },
        product: { only: [:id, :name, :external_id] }
      },
      methods: [:subtotal]
    )
  end

  def create
    @order_item = OrderItem.new(order_item_params)
    
    if @order_item.save
      render json: @order_item.as_json(
        include: { product: { only: [:id, :name, :external_id] } },
        methods: [:subtotal]
      ), status: :created
    else
      render json: { errors: @order_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @order_item.update(order_item_params)
      render json: @order_item.as_json(
        include: { product: { only: [:id, :name, :external_id] } },
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
    params.require(:order_item).permit(:order_id, :product_id, :quantity, :unit_price)
  end
end
