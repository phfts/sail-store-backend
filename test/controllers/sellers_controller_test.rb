require "test_helper"

class SellersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = sellers(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    store = stores(:one)
    get "/stores/#{store.slug}/sellers", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
        params: { 
          seller: { 
            store_id: @seller.store_id, 
            company_id: @seller.company_id,
            name: "Novo Vendedor #{Time.current.to_i}", 
            whatsapp: "11987654321" 
          } 
        }, 
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
            company_id: @seller.company_id,
            name: "Vendedor com Login #{Time.current.to_i}", 
            whatsapp: "11987654321",
            email: "vendedor#{Time.current.to_i}@teste.com",
            password: "senha123"
          } 
        }, 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    end

    assert_response :created
    
    # Verificar se o usuário foi criado
    user = User.last
    assert user.authenticate("senha123")
  end

  test "should create seller with formatted whatsapp" do
    assert_difference("Seller.count") do
      post sellers_url, 
        params: { 
          seller: { 
            store_id: @seller.store_id, 
            company_id: @seller.company_id,
            name: "Vendedor com WhatsApp #{Time.current.to_i}", 
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
          company_id: @seller.company_id,
          name: "Vendedor com WhatsApp Inválido #{Time.current.to_i}", 
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
    # Criar um seller temporário sem user para o teste
    temp_seller = Seller.create!(
      store: @seller.store,
      company: @seller.company,
      name: "Temp Seller Update #{Time.current.to_i}",
      whatsapp: "11987654321"
    )
    
    patch seller_url(temp_seller), 
      params: { 
        seller: { 
          name: "Vendedor Atualizado #{Time.current.to_i}", 
          whatsapp: "11987654321" 
        } 
      }, 
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
    # Criar um seller temporário para o teste
    temp_seller = Seller.create!(
      store: @seller.store,
      company: @seller.company,
      name: "Temp Seller Busy #{Time.current.to_i}",
      whatsapp: "11987654321",
      is_busy: false
    )
    
    put busy_status_seller_url(temp_seller), 
      params: { is_busy: true }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    
    assert_response :success
    
    response_data = JSON.parse(@response.body)
    assert_equal "Vendedor marcado como ocupado com sucesso", response_data['message']
    assert_equal true, response_data['seller']['is_busy']
    
    temp_seller.reload
    assert_equal true, temp_seller.is_busy
  end

  test "should update seller busy status to false" do
    # Criar um seller temporário para o teste
    temp_seller = Seller.create!(
      store: @seller.store,
      company: @seller.company,
      name: "Temp Seller #{Time.current.to_i}",
      whatsapp: "11987654321",
      is_busy: true
    )
    
    put busy_status_seller_url(temp_seller), 
      params: { is_busy: false }, 
      headers: { 'Authorization' => "Bearer #{@token}" },
      as: :json
    
    assert_response :success
    
    response_data = JSON.parse(@response.body)
    assert_equal "Vendedor marcado como disponível com sucesso", response_data['message']
    assert_equal false, response_data['seller']['is_busy']
    
    temp_seller.reload
    assert_equal false, temp_seller.is_busy
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
    # Criar um seller temporário para o teste
    temp_seller = Seller.create!(
      store: @seller.store,
      company: @seller.company,
      name: "Temp Seller #{Time.current.to_i}",
      whatsapp: "11987654321",
      is_busy: true
    )
    
    get seller_url(temp_seller), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
