class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    # Filtrar categorias da empresa do usuário atual
    if current_user.admin?
      @categories = Category.all
    else
      @categories = current_user.store.company.categories
    end
    
    @categories = @categories.map do |category|
      category.as_json.merge(
        products_count: category.products_count
      )
    end
    render json: @categories
  end

  def show
    render json: @category
  end

  def create
    @category = Category.new(category_params)
    
    if @category.save
      render json: @category, status: :created
    else
      render_validation_errors(@category)
    end
  end

  def update
    if @category.update(category_params)
      render json: @category
    else
      render_validation_errors(@category)
    end
  end

  def destroy
    @category.destroy
    render json: { message: "Categoria excluída com sucesso" }
  end

  private

  def set_category
    if current_user.admin?
      @category = Category.find(params[:id])
    else
      @category = current_user.store.company.categories.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found_error("Categoria não encontrada")
  end

  def category_params
    params.require(:category).permit(:external_id, :name, :company_id)
  end
end
