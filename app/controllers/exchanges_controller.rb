class ExchangesController < ApplicationController
  before_action :set_exchange, only: [:show, :update, :destroy]

  def index
    @exchanges = Exchange.includes(:seller, :original_order, :new_order)
    
    # Filtros
    if params[:seller_id]
      @exchanges = @exchanges.where(seller_id: params[:seller_id])
    end
    
    if params[:store_id]
      @exchanges = @exchanges.joins(:seller).where(sellers: { store_id: params[:store_id] })
    end
    
    if params[:exchange_type]
      @exchanges = @exchanges.where(exchange_type: params[:exchange_type])
    end
    
    if params[:is_credit]
      @exchanges = @exchanges.where(is_credit: params[:is_credit])
    end
    
    if params[:start_date] && params[:end_date]
      @exchanges = @exchanges.where(processed_at: params[:start_date]..params[:end_date])
    end
    
    # Paginação
    @exchanges = @exchanges.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      exchanges: @exchanges.as_json(
        include: { 
          seller: { only: [:id, :name, :external_id] },
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          new_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          }
        },
        methods: [:formatted_value, :credit?, :debit?],
        except: [:created_at, :updated_at]
      ),
      pagination: {
        current_page: @exchanges.current_page,
        total_pages: @exchanges.total_pages,
        total_count: @exchanges.total_count,
        per_page: @exchanges.limit_value
      }
    }
  end

  def show
    render json: @exchange.as_json(
      include: { 
        seller: { only: [:id, :name, :external_id] },
        original_order: { 
          only: [:id, :external_id, :sold_at],
          include: { seller: { only: [:id, :name, :external_id] } }
        },
        new_order: { 
          only: [:id, :external_id, :sold_at],
          include: { seller: { only: [:id, :name, :external_id] } }
        }
      },
      methods: [:formatted_value, :credit?, :debit?],
      except: [:created_at, :updated_at]
    )
  end

  def create
    @exchange = Exchange.new(exchange_params)
    
    if @exchange.save
      render json: @exchange.as_json(
        include: { 
          seller: { only: [:id, :name, :external_id] },
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          new_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          }
        },
        methods: [:formatted_value, :credit?, :debit?],
        except: [:created_at, :updated_at]
      ), status: :created
    else
      render_validation_errors(@exchange)
    end
  end

  def update
    if @exchange.update(exchange_params)
      render json: @exchange.as_json(
        include: { 
          seller: { only: [:id, :name, :external_id] },
          original_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          },
          new_order: { 
            only: [:id, :external_id, :sold_at],
            include: { seller: { only: [:id, :name, :external_id] } }
          }
        },
        methods: [:formatted_value, :credit?, :debit?],
        except: [:created_at, :updated_at]
      )
    else
      render_validation_errors(@exchange)
    end
  end

  def destroy
    @exchange.destroy
    render json: { message: "Troca excluída com sucesso" }
  end

  def stats
    exchanges = Exchange.includes(:seller, :original_order, :new_order)
    
    # Filtros
    if params[:seller_id]
      exchanges = exchanges.where(seller_id: params[:seller_id])
    end
    
    if params[:store_id]
      exchanges = exchanges.joins(:seller).where(sellers: { store_id: params[:store_id] })
    end
    
    if params[:start_date] && params[:end_date]
      exchanges = exchanges.where(processed_at: params[:start_date]..params[:end_date])
    end
    
    total_exchanges = exchanges.count
    total_value = exchanges.sum(:voucher_value)
    credit_exchanges = exchanges.where(is_credit: true).count
    credit_value = exchanges.where(is_credit: true).sum(:voucher_value)
    debit_exchanges = exchanges.where(is_credit: false).count
    debit_value = exchanges.where(is_credit: false).sum(:voucher_value)
    
    render json: {
      total_exchanges: total_exchanges,
      total_value: total_value,
      credit_exchanges: {
        count: credit_exchanges,
        value: credit_value
      },
      debit_exchanges: {
        count: debit_exchanges,
        value: debit_value
      },
      period: {
        start_date: params[:start_date],
        end_date: params[:end_date]
      }
    }
  end

  def types
    exchange_types = Exchange.distinct.pluck(:exchange_type).compact.sort
    
    render json: {
      exchange_types: exchange_types
    }
  end

  private

  def set_exchange
    @exchange = Exchange.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found_error("Troca não encontrada")
  end

  def exchange_params
    params.require(:exchange).permit(
      :external_id,
      :voucher_number,
      :voucher_value,
      :original_document,
      :new_document,
      :customer_code,
      :exchange_type,
      :is_credit,
      :processed_at,
      :seller_id,
      :original_order_id,
      :new_order_id
    )
  end
end
