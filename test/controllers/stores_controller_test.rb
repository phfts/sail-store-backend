require "test_helper"

class StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @store = stores(:one)
    @admin = users(:admin)
    @regular_user = users(:one)
  end

  def login_and_get_token(user, password)
    post auth_login_url, params: { username: user.username, password: password }, as: :json
    assert_response :success
    response_data = JSON.parse(response.body)
    response_data['token']
  end

  test "should get index" do
    # Login como admin
    token = login_and_get_token(@admin, 'admin123')
    
    get stores_url, headers: { 'Authorization': "Bearer #{token}" }, as: :json
    assert_response :success
  end

  test "should create store as admin" do
    # Login como admin
    token = login_and_get_token(@admin, 'admin123')
    
    assert_difference("Store.count") do
      post stores_url, params: { store: { address: @store.address, cnpj: @store.cnpj, name: @store.name } }, 
           headers: { 'Authorization': "Bearer #{token}" }, as: :json
    end

    assert_response :created
  end

  test "should not create store as regular user" do
    # Login como usuário regular
    token = login_and_get_token(@regular_user, 'password123')
    
    assert_no_difference("Store.count") do
      post stores_url, params: { store: { address: @store.address, cnpj: @store.cnpj, name: @store.name } }, 
           headers: { 'Authorization': "Bearer #{token}" }, as: :json
    end

    assert_response :forbidden
  end

  test "should show store" do
    # Login como admin
    token = login_and_get_token(@admin, 'admin123')
    
    get store_url(@store), headers: { 'Authorization': "Bearer #{token}" }, as: :json
    assert_response :success
  end

  test "should update store as admin" do
    # Login como admin
    token = login_and_get_token(@admin, 'admin123')
    
    patch store_url(@store), params: { store: { address: @store.address, cnpj: @store.cnpj, name: @store.name } }, 
          headers: { 'Authorization': "Bearer #{token}" }, as: :json
    assert_response :success
  end

  test "should not update store as regular user" do
    # Login como usuário regular
    token = login_and_get_token(@regular_user, 'password123')
    
    patch store_url(@store), params: { store: { address: @store.address, cnpj: @store.cnpj, name: @store.name } }, 
          headers: { 'Authorization': "Bearer #{token}" }, as: :json
    assert_response :forbidden
  end

  test "should destroy store as admin" do
    # Login como admin
    token = login_and_get_token(@admin, 'admin123')
    
    assert_difference("Store.count", -1) do
      delete store_url(@store), headers: { 'Authorization': "Bearer #{token}" }, as: :json
    end

    assert_response :no_content
  end

  test "should not destroy store as regular user" do
    # Login como usuário regular
    token = login_and_get_token(@regular_user, 'password123')
    
    assert_no_difference("Store.count") do
      delete store_url(@store), headers: { 'Authorization': "Bearer #{token}" }, as: :json
    end

    assert_response :forbidden
  end

  test "should require authentication" do
    get stores_url, as: :json
    assert_response :unauthorized
  end

  test "should reject invalid token" do
    get stores_url, headers: { 'Authorization': 'Bearer invalid_token' }, as: :json
    assert_response :unauthorized
  end
end
