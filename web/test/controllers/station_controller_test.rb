require 'test_helper'

class StationControllerTest < ActionController::TestCase
  test "should get dj_booth" do
    get :dj_booth
    assert_response :success
  end

  test "should get playlist_editor" do
    get :playlist_editor
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get create" do
    get :create
    assert_response :success
  end

end
