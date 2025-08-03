require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sales_index_url
    assert_response :success
  end

  test "should get show" do
    get sales_show_url
    assert_response :success
  end

  test "should get create" do
    get sales_create_url
    assert_response :success
  end

  test "should get update" do
    get sales_update_url
    assert_response :success
  end

  test "should get destroy" do
    get sales_destroy_url
    assert_response :success
  end
end
