class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = generate_jwt_token(user)
      
      # Registrar log de login
      LoginLog.create!(
        user: user,
        login_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      render json: {
        message: 'Login realizado com sucesso',
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          admin: user.admin?
        }
      }, status: :ok
    else
      render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
    end
  end
  
  def logout
    # Com JWT, o logout é principalmente no frontend
    # Mas podemos usar este endpoint para logging ou futuras funcionalidades
    render json: { message: 'Logout realizado com sucesso' }, status: :ok
  end
  
  def register
    user = User.new(user_params)
    
    if user.save
      token = generate_jwt_token(user)
      
      render json: {
        message: 'Usuário registrado com sucesso',
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          admin: user.admin?
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def me
    if current_user
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          email: current_user.email,
          admin: current_user.admin?
        }
      }, status: :ok
    else
      render json: { error: 'Usuário não autenticado' }, status: :unauthorized
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
