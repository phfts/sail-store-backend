class ApplicationController < ActionController::API
  before_action :authenticate_user!
  
  private
  
  def authenticate_user!
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    begin
      decoded = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' })
      @current_user = User.find(decoded[0]['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Token inválido ou expirado' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def require_admin!
    unless current_user&.admin?
      render json: { error: 'Acesso negado. Apenas administradores podem acessar este recurso.' }, status: :forbidden
    end
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
  end

  def render_validation_errors(record)
    errors = record.errors.full_messages
    render json: { 
      error: 'Erro de validação',
      message: 'Os dados fornecidos não são válidos',
      details: errors,
      errors: errors
    }, status: :unprocessable_entity
  end

  def render_not_found_error(message = 'Recurso não encontrado')
    render json: { 
      error: 'Não encontrado',
      message: message
    }, status: :not_found
  end

  def render_forbidden_error(message = 'Acesso negado')
    render json: { 
      error: 'Acesso negado',
      message: message
    }, status: :forbidden
  end

  def render_unauthorized_error(message = 'Não autorizado')
    render json: { 
      error: 'Não autorizado',
      message: message
    }, status: :unauthorized
  end
end
