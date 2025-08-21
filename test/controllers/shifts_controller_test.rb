require "test_helper"

class ShiftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shift = shifts(:one)
    @store = stores(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get "/stores/#{@store.slug}/shifts", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get show" do
    get "/stores/#{@store.slug}/shifts/#{@shift.id}", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get create" do
    post "/stores/#{@store.slug}/shifts", params: { 
      shift: { 
        name: "Test Shift",
        start_time: "09:00",
        end_time: "17:00"
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get update" do
    put "/stores/#{@store.slug}/shifts/#{@shift.id}", params: { 
      shift: { 
        name: "Updated Shift",
        start_time: "10:00",
        end_time: "18:00"
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete "/stores/#{@store.slug}/shifts/#{@shift.id}", headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
