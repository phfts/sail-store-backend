require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get products_url, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get show" do
    get product_url(@product), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get create" do
    category = categories(:one)
    
    post products_url, params: { 
      product: { 
        name: "Test Product", 
        external_id: "TEST123",
        sku: "SKU123",
        category_id: category.id
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get update" do
    category = categories(:one)
    
    patch product_url(@product), params: { 
      product: { 
        name: "Updated Product",
        external_id: "UPDATED123",
        sku: "UPDATED123",
        category_id: category.id
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete product_url(@product), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
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
