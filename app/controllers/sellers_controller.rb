class SellersController < ApplicationController
  before_action :set_seller, only: %i[ show update destroy ]
  before_action :require_admin!, only: %i[ create update destroy ]

  # GET /sellers
  def index
    @sellers = Seller.includes(:user).all
    render json: @sellers.map { |seller| seller_response(seller) }
  end

  # GET /sellers/1
  def show
    render json: seller_response(@seller)
  end

  # POST /sellers
  def create
    @seller = Seller.new(seller_params)

    if @seller.save
      render json: seller_response(@seller), status: :created
    else
      render json: { errors: @seller.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sellers/1
  def update
    if @seller.update(seller_params)
      render json: seller_response(@seller)
    else
      render json: { errors: @seller.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /sellers/1
  def destroy
    @seller.destroy
    render json: { message: 'Vendedor excluído com sucesso' }
  end

  private

  def set_seller
    @seller = Seller.find(params[:id])
  end

  def seller_params
    params.require(:seller).permit(:user_id, :store_id, :whatsapp, :email)
  end

  def seller_response(seller)
    {
      id: seller.id,
      user_id: seller.user_id,
      store_id: seller.store_id,
      user: {
        id: seller.user.id,
        username: seller.user.username,
        email: seller.user.email,
        admin: seller.user.admin?
      },
      store: {
        id: seller.store.id,
        name: seller.store.name,
        slug: seller.store.slug
      },
      whatsapp: seller.whatsapp,
      email: seller.email,
      formatted_whatsapp: seller.formatted_whatsapp,
      created_at: seller.created_at,
      updated_at: seller.updated_at
    }
  end
end
