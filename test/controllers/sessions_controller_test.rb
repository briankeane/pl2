require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "should get create_with_twitter" do
    get :create_with_twitter
    assert_response :success
  end

  test "should get destroy" do
    get :destroy
    assert_response :success
  end

end
