require "test_helper"

class SellersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = sellers(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get sellers_url, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get sellers by store slug" do
    store = stores(:one)
    get "/stores/#{store.slug}/sellers", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should create seller" do
    assert_difference("Seller.count") do
      post sellers_url, 
        params: { seller: { store_id: @seller.store_id, name: "Novo Vendedor", whatsapp: "11987654321" } }, 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    end

    assert_response :created
  end

  test "should create seller with email and password" do
    assert_difference(["Seller.count", "User.count"]) do
      post sellers_url, 
        params: { 
          seller: { 
            store_id: @seller.store_id, 
            name: "Vendedor com Login", 
            whatsapp: "11987654321",
            email: "vendedor@teste.com",
            password: "senha123"
          } 
        }, 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    end

    assert_response :created
    
    # Verificar se o usuário foi criado
    user = User.find_by(email: "vendedor@teste.com")
    assert user
    assert user.authenticate("senha123")
  end

  test "should create seller with formatted whatsapp" do
    assert_difference("Seller.count") do
      post sellers_url, 
        params: { 
          seller: { 
            store_id: @seller.store_id, 
            name: "Vendedor com WhatsApp Formatado", 
            whatsapp: "(11) 93747-0101"
          } 
        }, 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    end

    assert_response :created
    
    # Verificar se o WhatsApp foi normalizado (apenas números)
    seller = Seller.last
    assert_equal "5511937470101", seller.whatsapp
  end

  test "should reject invalid whatsapp" do
    post sellers_url, 
      params: { 
        seller: { 
          store_id: @seller.store_id, 
          name: "Vendedor com WhatsApp Inválido", 
          whatsapp: "123"
        } 
      }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json

    assert_response :unprocessable_entity
    assert_includes response.body, "deve ter pelo menos 10 dígitos"
  end

  test "should show seller" do
    get seller_url(@seller), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should update seller" do
    patch seller_url(@seller), 
      params: { seller: { name: "Vendedor Atualizado", whatsapp: "11987654321" } }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    assert_response :success
  end

  test "should destroy seller" do
    assert_difference("Seller.count", -1) do
      delete seller_url(@seller), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    end

    assert_response :success
  end

  test "should update seller busy status to true" do
    put busy_status_seller_url(@seller), 
      params: { is_busy: true }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    
    assert_response :success
    
    response_data = JSON.parse(@response.body)
    assert_equal "Vendedor marcado como ocupado com sucesso", response_data['message']
    assert_equal true, response_data['seller']['is_busy']
    
    @seller.reload
    assert_equal true, @seller.is_busy
  end

  test "should update seller busy status to false" do
    @seller.update!(is_busy: true)
    
    put busy_status_seller_url(@seller), 
      params: { is_busy: false }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    
    assert_response :success
    
    response_data = JSON.parse(@response.body)
    assert_equal "Vendedor marcado como disponível com sucesso", response_data['message']
    assert_equal false, response_data['seller']['is_busy']
    
    @seller.reload
    assert_equal false, @seller.is_busy
  end

  test "should return error when is_busy parameter is missing" do
    put busy_status_seller_url(@seller), 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    
    assert_response :unprocessable_entity
    
    response_data = JSON.parse(@response.body)
    assert_equal "Parâmetro is_busy é obrigatório", response_data['error']
  end

  test "should include is_busy field in seller response" do
    @seller.update!(is_busy: true)
    
    get seller_url(@seller), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
    
    response_data = JSON.parse(@response.body)
    assert_equal true, response_data['is_busy']
  end

  test "should deny access without authentication" do
    get sellers_url, as: :json
    assert_response :unauthorized
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
