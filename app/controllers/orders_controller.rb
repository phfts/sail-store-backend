class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update, :destroy]

  def index
    @orders = Order.includes(:seller, :order_items => [:product])
    
    if params[:seller_id]
      @orders = @orders.where(seller_id: params[:seller_id])
    end
    
    if params[:store_id]
      @orders = @orders.joins(:seller).where(sellers: { store_id: params[:store_id] })
    end
    
    render json: @orders.as_json(
      include: { 
        seller: { only: [:id, :name, :external_id] },
        order_items: {
          include: { product: { only: [:id, :name, :external_id] } }
        }
      },
      methods: [:total],
      except: [:created_at, :updated_at]
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
      methods: [:total],
      except: [:created_at, :updated_at]
    )
  end

  def create
    @order = Order.new(order_params)
    
    if @order.save
      render json: @order.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total],
        except: [:created_at, :updated_at]
      ), status: :created
    else
      render_validation_errors(@order)
    end
  end

  def update
    if @order.update(order_params)
      render json: @order.as_json(
        include: { seller: { only: [:id, :name, :external_id] } },
        methods: [:total],
        except: [:created_at, :updated_at]
      )
    else
      render_validation_errors(@order)
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
    render_not_found_error("Pedido não encontrado")
  end

  def order_params
    params.require(:order).permit(:external_id, :seller_id, :store_id, :sold_at, 
      order_items_attributes: [:product_id, :store_id, :quantity, :unit_price])
  end
end
