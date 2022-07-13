require "test_helper"

#class IpWhiteListsControllerTest < ActionDispatch::IntegrationTest
class IpWhiteListsControllerTest < ActionController::TestCase
  setup do
    @ip_white_list = ip_white_lists(:one)
  end

  test "should get index by admin" do
    session[:user_id] = users(:users_one).id
    get :index
    assert_response :success
  end

  test "should not get index by no-admin" do
    session[:user_id] = users(:users_two).id
    get :index
    assert_redirected_to root_url
  end

  test "should get new by admin" do
    session[:user_id] = users(:users_one).id
    get :new
    assert_response :success
  end

  test "should not get new by no-admin" do
    session[:user_id] = users(:users_two).id
    get :new
    assert_redirected_to root_url
  end

  test "should create ip_white_list by admin" do
    session[:user_id] = users(:users_one).id
    assert_difference('IpWhiteList.count') do
      post :create, params: { ip_white_list: { expired_at: @ip_white_list.expired_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    end

    assert_redirected_to ip_white_list_url(IpWhiteList.last)
  end

  test "should create ip_white_list by no-admin" do
    session[:user_id] = users(:users_two).id
    assert_no_difference('IpWhiteList.count') do
      post :create, params: { ip_white_list: { expired_at: @ip_white_list.expired_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    end
    assert_redirected_to root_url
  end


  test "should show ip_white_list by admin" do
    session[:user_id] = users(:users_one).id
    get :show, params: {id: @ip_white_list.id}
    assert_response :success
  end

  test "should show ip_white_list by no-admin" do
    session[:user_id] = users(:users_two).id
    get :show, params: {id: @ip_white_list.id}
    assert_redirected_to root_url
  end

  test "should get edit by admin" do
    session[:user_id] = users(:users_one).id
    get :edit, params: {id: @ip_white_list.id}
    assert_response :success
  end

  test "should get edit by no-admin" do
    session[:user_id] = users(:users_two).id
    get :edit, params: {id: @ip_white_list.id}
    assert_redirected_to root_url
  end

  test "should update ip_white_list by admin" do
    session[:user_id] = users(:users_one).id
    patch :update, params: { id: @ip_white_list.id, ip_white_list: { expired_at: @ip_white_list.expired_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    assert_redirected_to ip_white_list_url(@ip_white_list)
  end

  test "should update ip_white_list by no-admin" do
    session[:user_id] = users(:users_two).id
    patch :update, params: { id: @ip_white_list.id, ip_white_list: { expired_at: @ip_white_list.expired_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    assert_redirected_to root_url
  end

  test "should destroy ip_white_list by admin" do
    session[:user_id] = users(:users_one).id
    assert_difference('IpWhiteList.count', -1) do
      delete :destroy, params: { id: @ip_white_list.id}
    end
    assert_redirected_to ip_white_lists_url
  end

  test "should destroy ip_white_list by no-admin" do
    session[:user_id] = users(:users_two).id
    assert_no_difference('IpWhiteList.count', -1) do
      delete :destroy, params: { id: @ip_white_list.id}
    end
    assert_redirected_to root_url
  end

end
