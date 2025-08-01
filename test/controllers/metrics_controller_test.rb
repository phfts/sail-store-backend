require "test_helper"

class MetricsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin)
    @regular_user = users(:regular)
  end

  test "should get metrics when user is admin" do
    token = generate_jwt_token(@admin_user)
    
    get metrics_url, headers: { 'Authorization' => "Bearer #{token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_includes json_response.keys, 'total_stores'
    assert_includes json_response.keys, 'total_users'
    assert_includes json_response.keys, 'monthly_active_users'
    assert_includes json_response.keys, 'weekly_active_users'
    assert_includes json_response.keys, 'daily_active_users'
  end

  test "should deny access when user is not admin" do
    token = generate_jwt_token(@regular_user)
    
    get metrics_url, headers: { 'Authorization' => "Bearer #{token}" }
    
    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_equal 'Acesso negado. Apenas administradores podem acessar este recurso.', json_response['error']
  end

  test "should deny access without authentication" do
    get metrics_url
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'Token inválido ou expirado', json_response['error']
  end

  private

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end

  def jwt_secret_key
    ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
  end
end
