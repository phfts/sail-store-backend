class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[ show update destroy ]

  # GET /users
  def index
    @users = User.all
    render json: @users.map { |user| user_response(user) }
  end

  # GET /users/available
  def available
    # Buscar usuários que não são sellers
    @users = User.left_joins(:seller).where(sellers: { id: nil })
    render json: @users.map { |user| user_response(user) }
  end

  # GET /users/1
  def show
    render json: user_response(@user)
  end

  # POST /users
  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: user_response(@user), status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      render json: user_response(@user)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    if @user == current_user
      render json: { error: 'Não é possível excluir seu próprio usuário' }, status: :unprocessable_entity
    else
      @user.destroy
      render json: { message: 'Usuário excluído com sucesso' }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :admin)
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      admin: user.admin?,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
