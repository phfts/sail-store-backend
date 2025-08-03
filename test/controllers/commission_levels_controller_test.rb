require "test_helper"

class CommissionLevelsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get commission_levels_index_url
    assert_response :success
  end

  test "should get show" do
    get commission_levels_show_url
    assert_response :success
  end

  test "should get create" do
    get commission_levels_create_url
    assert_response :success
  end

  test "should get update" do
    get commission_levels_update_url
    assert_response :success
  end

  test "should get destroy" do
    get commission_levels_destroy_url
    assert_response :success
  end
end
