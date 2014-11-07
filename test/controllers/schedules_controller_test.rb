require 'test_helper'

class SchedulesControllerTest < ActionController::TestCase
  test "should get update_order" do
    get :update_order
    assert_response :success
  end

  test "should get add_spin" do
    get :add_spin
    assert_response :success
  end

  test "should get remove_spin" do
    get :remove_spin
    assert_response :success
  end

end
