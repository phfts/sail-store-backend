require "test_helper"

class VacationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vacations_index_url
    assert_response :success
  end

  test "should get show" do
    get vacations_show_url
    assert_response :success
  end

  test "should get create" do
    get vacations_create_url
    assert_response :success
  end

  test "should get update" do
    get vacations_update_url
    assert_response :success
  end

  test "should get destroy" do
    get vacations_destroy_url
    assert_response :success
  end
end
