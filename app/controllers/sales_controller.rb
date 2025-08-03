class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sale, only: [:show, :update, :destroy]

  def index
    if current_user.admin?
      # Admins podem ver todas as vendas
      @sales = Sale.joins(:seller => :store)
                   .includes(:seller)
                   .recent
    else
      # Usuários regulares veem apenas as vendas da sua loja
      @sales = current_user.store.sales
                           .includes(:seller)
                           .recent
    end
    
    # Filtrar por seller_id se especificado
    if params[:seller_id].present?
      @sales = @sales.by_seller(params[:seller_id])
    end
    
    # Filtrar por período se especificado
    if params[:start_date].present? && params[:end_date].present?
      @sales = @sales.by_date_range(params[:start_date], params[:end_date])
    end

    render json: @sales.as_json(
      include: { 
        seller: { 
          only: [:id, :name, :code],
          methods: [:display_name]
        } 
      },
      methods: [:formatted_value, :formatted_date]
    )
  end

  def show
    render json: @sale.as_json(
      include: { 
        seller: { 
          only: [:id, :name, :code],
          methods: [:display_name]
        } 
      },
      methods: [:formatted_value, :formatted_date]
    )
  end

  def create
    @sale = Sale.new(sale_params)
    
    # Verificar se o seller pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      seller = current_user.store.sellers.find_by(id: @sale.seller_id)
      unless seller
        render json: { error: 'Vendedor não encontrado ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    if @sale.save
      render json: @sale.as_json(
        include: { 
          seller: { 
            only: [:id, :name, :code],
            methods: [:display_name]
          } 
        },
        methods: [:formatted_value, :formatted_date]
      ), status: :created
    else
      render json: { errors: @sale.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    # Verificar se a venda pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      unless current_user.store.sales.exists?(@sale.id)
        render json: { error: 'Venda não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    if @sale.update(sale_params)
      render json: @sale.as_json(
        include: { 
          seller: { 
            only: [:id, :name, :code],
            methods: [:display_name]
          } 
        },
        methods: [:formatted_value, :formatted_date]
      )
    else
      render json: { errors: @sale.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # Verificar se a venda pertence à loja do usuário (se não for admin)
    unless current_user.admin?
      unless current_user.store.sales.exists?(@sale.id)
        render json: { error: 'Venda não encontrada ou não pertence à sua loja' }, status: :not_found
        return
      end
    end

    @sale.destroy
    render json: { message: 'Venda excluída com sucesso' }
  end

  private

  def set_sale
    @sale = Sale.find(params[:id])
  end

  def sale_params
    params.require(:sale).permit(:seller_id, :value, :sold_at)
  end
end
