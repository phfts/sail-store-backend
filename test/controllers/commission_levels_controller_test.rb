require "test_helper"

class CommissionLevelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @commission_level = commission_levels(:one)
    @store = stores(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get "/stores/#{@store.slug}/commission_levels", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get show" do
    get "/stores/#{@store.slug}/commission_levels/#{@commission_level.id}", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get create" do
    post "/stores/#{@store.slug}/commission_levels", params: { 
      commission_level: { 
        name: "Test Level", 
        achievement_percentage: 80.0,
        commission_percentage: 10.0
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get update" do
    put "/stores/#{@store.slug}/commission_levels/#{@commission_level.id}", params: { commission_level: { name: "Updated Level" } }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete "/stores/#{@store.slug}/commission_levels/#{@commission_level.id}", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
