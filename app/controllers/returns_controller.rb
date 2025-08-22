class ReturnsController < ApplicationController
  before_action :set_return, only: [:show, :update, :destroy]

  def index
    @returns = Return.includes(:original_order, :product)
    
    # Filtros
    if params[:seller_id]
      @returns = @returns.joins(:original_order).where(orders: { seller_id: params[:seller_id] })
    end
    
    if params[:store_id]
      @returns = @returns.joins(original_order: :seller).where(sellers: { store_id: params[:store_id] })
    end
    
    if params[:product_id]
      @returns = @returns.where(product_id: params[:product_id])
    end
    
    if params[:start_date] && params[:end_date]
      @returns = @returns.where(processed_at: params[:start_date]..params[:end_date])
    end
    
    # Paginação
    @returns = @returns.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      returns: @returns.as_json(
        include: { 
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          product: { only: [:id, :name, :external_id, :sku] }
        },
        methods: [:return_value, :formatted_quantity],
        except: [:created_at, :updated_at]
      ),
      pagination: {
        current_page: @returns.current_page,
        total_pages: @returns.total_pages,
        total_count: @returns.total_count,
        per_page: @returns.limit_value
      }
    }
  end

  def show
    render json: @return.as_json(
      include: { 
        original_order: { 
          only: [:id, :external_id, :sold_at],
          include: { seller: { only: [:id, :name, :external_id] } }
        },
        product: { only: [:id, :name, :external_id, :sku] }
      },
      methods: [:return_value, :formatted_quantity],
      except: [:created_at, :updated_at]
    )
  end

  def create
    @return = Return.new(return_params)
    
    if @return.save
      render json: @return.as_json(
        include: { 
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          product: { only: [:id, :name, :external_id, :sku] }
        },
        methods: [:return_value, :formatted_quantity],
        except: [:created_at, :updated_at]
      ), status: :created
    else
      render_validation_errors(@return)
    end
  end

  def update
    if @return.update(return_params)
      render json: @return.as_json(
        include: { 
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          product: { only: [:id, :name, :external_id, :sku] }
        },
        methods: [:return_value, :formatted_quantity],
        except: [:created_at, :updated_at]
      )
    else
      render_validation_errors(@return)
    end
  end

  def destroy
    @return.destroy
    render json: { message: "Devolução excluída com sucesso" }
  end

  def stats
    returns = Return.includes(:original_order, :product)
    
    # Filtros
    if params[:seller_id]
      returns = returns.joins(:original_order).where(orders: { seller_id: params[:seller_id] })
    end
    
    if params[:store_id]
      returns = returns.joins(original_order: :seller).where(sellers: { store_id: params[:store_id] })
    end
    
    if params[:start_date] && params[:end_date]
      returns = returns.where(processed_at: params[:start_date]..params[:end_date])
    end
    
    total_returns = returns.count
    total_value = returns.sum(&:return_value)
    avg_value = total_returns > 0 ? total_value / total_returns : 0
    
    render json: {
      total_returns: total_returns,
      total_value: total_value,
      average_value: avg_value,
      period: {
        start_date: params[:start_date],
        end_date: params[:end_date]
      }
    }
  end

  private

  def set_return
    @return = Return.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found_error("Devolução não encontrada")
  end

  def return_params
    params.require(:return).permit(
      :external_id, 
      :original_sale_id,
      :product_external_id,
      :original_transaction,
      :return_transaction,
      :quantity_returned,
      :processed_at,
      :original_order_id,
      :product_id
    )
  end
end
