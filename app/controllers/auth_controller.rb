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
          email: user.email,
          admin: user.admin?,
          store_admin: user.store_admin?,
          store_slug: user.store_slug
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
          email: user.email,
          admin: user.admin?,
          store_admin: user.store_admin?,
          store_slug: user.store_slug
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
          email: current_user.email,
          admin: current_user.admin?,
          store_admin: current_user.store_admin?,
          store_slug: current_user.store_slug
        }
      }, status: :ok
    else
      render json: { error: 'Usuário não autenticado' }, status: :unauthorized
    end
  end

  def generate_api_token
    # Apenas admins podem gerar tokens de API
    require_admin!
    
    # Parâmetros opcionais para personalizar o token
    email = params[:email] || "api_#{SecureRandom.hex(8)}@system.com"
    admin = params[:admin] == 'true'
    expires_in = params[:expires_in] || 1.year.to_i
    
    # Criar usuário para o token
    user = User.find_or_create_by(email: email) do |u|
      u.password = SecureRandom.hex(16)
      u.password_confirmation = u.password
      u.admin = admin
    end
    
    # Gerar token JWT
    payload = {
      user_id: user.id,
      email: user.email,
      admin: user.admin?,
      exp: Time.current.to_i + expires_in
    }
    
    token = generate_jwt_token(user)
    
    render json: {
      message: 'Token de API gerado com sucesso',
      token: token,
      user: {
        id: user.id,
        email: user.email,
        admin: user.admin?,
        expires_at: Time.at(payload[:exp])
      }
    }, status: :ok
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
