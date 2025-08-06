class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = Product.includes(:category)
    
    if params[:category_id]
      @products = @products.where(category_id: params[:category_id])
    end
    
    render json: @products.as_json(include: { category: { only: [:id, :external_id, :name] } })
  end

  def show
    render json: @product.as_json(include: { category: { only: [:id, :external_id, :name] } })
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      render json: @product.as_json(include: { category: { only: [:id, :external_id, :name] } }), status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      render json: @product.as_json(include: { category: { only: [:id, :external_id, :name] } })
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    render json: { message: "Produto excluído com sucesso" }
  end

  private

  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Produto não encontrado" }, status: :not_found
  end

  def product_params
    params.require(:product).permit(:external_id, :name, :sku, :category_id)
  end
end
