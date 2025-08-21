require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get categories_url, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get show" do
    get category_url(@category), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get create" do
    post categories_url, params: { category: { name: "Test Category", external_id: "test123", company_id: companies(:one).id } }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get update" do
    patch category_url(@category), params: { category: { name: "Updated Category" } }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete category_url(@category), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
