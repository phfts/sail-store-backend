class StoresController < ApplicationController
  before_action :set_store, only: %i[ show update destroy ]
  before_action :require_admin!, only: %i[ create update destroy ]

  # GET /stores
  def index
    if params[:company_id]
      @stores = Store.where(company_id: params[:company_id])
    else
      @stores = Store.all
    end

    render json: @stores
  end

  # GET /stores/1
  def show
    render json: @store
  end

  # GET /stores/by-slug/:slug
  def show_by_slug
    @store = Store.find_by!(slug: params[:slug])
    render json: @store
  end

  # GET /stores/by-external-id/:external_id
  def show_by_external_id
    @store = Store.find_by!(external_id: params[:external_id])
    render json: @store
  end

  # POST /stores
  def create
    @store = Store.new(store_params)

    if @store.save
      render json: @store, status: :created, location: @store
    else
      render json: @store.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stores/1
  def update
    if @store.update(store_params)
      render json: @store
    else
      render json: @store.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stores/1
  def destroy
    @store.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_store
      @store = Store.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def store_params
      params.require(:store).permit(:name, :cnpj, :address, :slug, :external_id, :company_id, :hide_ranking)
    end

    def require_admin!
      unless current_user&.admin?
        render json: { error: 'Acesso negado. Apenas administradores podem realizar esta ação.' }, status: :forbidden
      end
    end
end
