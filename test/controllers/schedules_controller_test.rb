require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = schedules(:one)
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
  end

  test "should get index" do
    get schedules_url, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get show" do
    get schedule_url(@schedule), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get create" do
    seller = sellers(:one)
    shift = shifts(:one)
    store = stores(:one)
    
    post schedules_url, params: { 
      schedule: { 
        seller_id: seller.id,
        shift_id: shift.id,
        store_id: store.id,
        date: Date.current
      } 
    }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get update" do
    patch schedule_url(@schedule), params: { schedule: { name: "Updated Schedule" } }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete schedule_url(@schedule), headers: { 'Authorization' => "Bearer #{@token}" }, as: :json
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
