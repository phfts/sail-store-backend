require "test_helper"

class QueueControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin)
    @token = generate_jwt_token(@admin_user)
    @store = stores(:one)
    @seller = sellers(:one)
    @queue_item = create_queue_item
  end

  test "should get queue index" do
    get "/stores/#{@store.slug}/queue", 
        headers: { 'Authorization' => "Bearer #{@token}" }, 
        as: :json
    assert_response :success
  end

  test "should get queue stats" do
    get "/stores/#{@store.slug}/queue/stats", 
        headers: { 'Authorization' => "Bearer #{@token}" }, 
        as: :json
    assert_response :success
  end

  test "should create queue item" do
    assert_difference("QueueItem.count") do
      post "/stores/#{@store.slug}/queue", 
           params: { 
             queue_item: { 
               priority: 1, 
               notes: "Cliente teste" 
             } 
           }, 
           headers: { 'Authorization' => "Bearer #{@token}" },
           as: :json
    end

    assert_response :created
  end

  test "should assign queue item to seller" do
    put "/queue/#{@queue_item.id}/assign", 
        params: { seller_id: @seller.id }, 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    
    assert_response :success
    
    @queue_item.reload
    assert_equal @seller.id, @queue_item.seller_id
    assert_equal 'in_service', @queue_item.status
  end

  test "should complete queue item" do
    @queue_item.assign_to_seller!(@seller)
    
    put "/queue/#{@queue_item.id}/complete", 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    
    assert_response :success
    
    @queue_item.reload
    assert_equal 'completed', @queue_item.status
    assert_not_nil @queue_item.completed_at
  end

  test "should cancel queue item" do
    put "/queue/#{@queue_item.id}/cancel", 
        headers: { 'Authorization' => "Bearer #{@token}" },
        as: :json
    
    assert_response :success
    
    @queue_item.reload
    assert_equal 'cancelled', @queue_item.status
    assert_not_nil @queue_item.completed_at
  end

  test "should get next customer" do
    get "/stores/#{@store.slug}/queue/next", 
        headers: { 'Authorization' => "Bearer #{@token}" }, 
        as: :json
    assert_response :success
  end

  test "should deny access without authentication" do
    get "/stores/#{@store.slug}/queue", as: :json
    assert_response :unauthorized
  end

  private

  def create_queue_item
    QueueItem.create!(
      store: @store,
      company: @store.company,
      status: 'waiting',
      priority: 1,
      notes: 'Test item'
    )
  end

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