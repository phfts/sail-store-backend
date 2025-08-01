class ApplicationController < ActionController::API
  before_action :authenticate_user!
  
  private
  
  def authenticate_user!
    unless current_user
      render json: { error: 'Acesso não autorizado' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user ||= begin
      token = extract_token_from_header
      return nil unless token
      
      decoded_token = decode_jwt_token(token)
      return nil unless decoded_token
      
      User.find_by(id: decoded_token['user_id'])
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end
  end
  
  def require_admin!
    unless current_user&.admin?
      render json: { error: 'Acesso negado. Apenas administradores podem acessar este recurso.' }, status: :forbidden
    end
  end
  
  def admin_only
    require_admin!
  end
  
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      username: user.username,
      admin: user.admin?,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def decode_jwt_token(token)
    decoded = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' })
    decoded.first
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
  
  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header
    
    auth_header.split(' ').last
  end
  
  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'your-secret-key-change-in-production'
  end
end
