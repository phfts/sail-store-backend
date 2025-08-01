require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular_user = users(:one)
  end

  test "should login with valid credentials" do
    post auth_login_url, params: { email: @admin.email, password: 'admin123' }, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal 'Login realizado com sucesso', response_data['message']
    assert_equal @admin.username, response_data['user']['username']
    assert response_data['user']['admin']
    assert response_data['token'] # Verificar se o token foi retornado
  end

  test "should not login with invalid credentials" do
    post auth_login_url, params: { email: @admin.email, password: 'wrong_password' }, as: :json
    assert_response :unauthorized
    
    response_data = JSON.parse(response.body)
    assert_equal 'Email ou senha inválidos', response_data['error']
  end

  test "should register new user" do
    assert_difference("User.count") do
      post auth_register_url, params: { 
        user: { 
          username: 'newuser', 
          email: 'newuser@example.com', 
          password: 'password123', 
          password_confirmation: 'password123' 
        } 
      }, as: :json
    end

    assert_response :created
    
    response_data = JSON.parse(response.body)
    assert_equal 'Usuário registrado com sucesso', response_data['message']
    assert_equal 'newuser', response_data['user']['username']
    assert_not response_data['user']['admin'] # Usuários registrados não são admin por padrão
    assert response_data['token'] # Verificar se o token foi retornado
  end

  test "should not register user with invalid data" do
    assert_no_difference("User.count") do
      post auth_register_url, params: { 
        user: { 
          username: '', 
          email: 'invalid_email', 
          password: '123', 
          password_confirmation: '123' 
        } 
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "should get current user info with valid token" do
    # Primeiro fazer login para obter token
    post auth_login_url, params: { email: @admin.email, password: 'admin123' }, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    token = response_data['token']
    
    # Verificar informações do usuário atual
    get auth_me_url, headers: { 'Authorization': "Bearer #{token}" }, as: :json
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal @admin.username, response_data['user']['username']
    assert_equal @admin.email, response_data['user']['email']
    assert response_data['user']['admin']
  end

  test "should not get current user info without token" do
    get auth_me_url, as: :json
    assert_response :unauthorized
    
    response_data = JSON.parse(response.body)
    assert_equal 'Acesso não autorizado', response_data['error']
  end

  test "should not get current user info with invalid token" do
    get auth_me_url, headers: { 'Authorization': 'Bearer invalid_token' }, as: :json
    assert_response :unauthorized
    
    response_data = JSON.parse(response.body)
    assert_equal 'Acesso não autorizado', response_data['error']
  end
end
