require "test_helper"

#class IpWhiteListsControllerTest < ActionDispatch::IntegrationTest
class IpWhiteListsControllerTest < ActionController::TestCase
  setup do
    @ip_white_list = ip_white_lists(:one)
  end

  test "should get index by admin" do
    session[:user_id] = users(:user_one).id
    get :index
    assert_response :success
  end

  test "should not get index by no-admin" do
    session[:user_id] = users(:user_two).id
    get :index
    assert_redirected_to error_url
  end

  test "should get new by admin" do
    session[:user_id] = users(:user_one).id
    get :new
    assert_response :success
  end

  test "should not get new by no-admin" do
    session[:user_id] = users(:user_two).id
    get :new
    assert_redirected_to error_url
  end

  test "should create ip_white_list by admin" do
    session[:user_id] = users(:user_one).id
    assert_difference('IpWhiteList.count') do
      post :create, params: { ip_white_list: { expires_at:'2022-08-02', ip:'192.168.0.1', memo:'my memo' } }
    end

    assert_redirected_to ip_white_lists_url
  end

  test "should not create invalid ip_white_list by admin" do
    session[:user_id] = users(:user_one).id
    [:ng1, :ng2, :ng3].each{|ng_ip_symbol|
      ng_ip = ip_white_lists(ng_ip_symbol)
      assert_no_difference('IpWhiteList.count') do
        post :create, params: { ip_white_list: { expires_at: ng_ip.expires_at, ip: ng_ip.ip, memo: ng_ip.memo } }
      end
      assert_response :unprocessable_entity
    }
  end


  test "should create ip_white_list by no-admin" do
    session[:user_id] = users(:user_two).id
    assert_no_difference('IpWhiteList.count') do
      post :create, params: { ip_white_list: { expires_at: @ip_white_list.expires_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    end
    assert_redirected_to error_url
  end


  test "should show ip_white_list by admin" do
    session[:user_id] = users(:user_one).id
    get :show, params: {id: @ip_white_list.id}
    assert_response :success
  end

  test "should show ip_white_list by no-admin" do
    session[:user_id] = users(:user_two).id
    get :show, params: {id: @ip_white_list.id}
    assert_redirected_to error_url
  end

  test "should get edit by admin" do
    session[:user_id] = users(:user_one).id
    get :edit, params: {id: @ip_white_list.id}
    assert_response :success
  end

  test "should get edit by no-admin" do
    session[:user_id] = users(:user_two).id
    get :edit, params: {id: @ip_white_list.id}
    assert_redirected_to error_url
  end

  test "should update ip_white_list by admin" do
    session[:user_id] = users(:user_one).id
    patch :update, params: { id: @ip_white_list.id, ip_white_list: { expires_at: @ip_white_list.expires_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    assert_redirected_to ip_white_lists_url
  end

  test "should update ip_white_list by no-admin" do
    session[:user_id] = users(:user_two).id
    patch :update, params: { id: @ip_white_list.id, ip_white_list: { expires_at: @ip_white_list.expires_at, ip: @ip_white_list.ip, memo: @ip_white_list.memo } }
    assert_redirected_to error_url
  end

  test "should destroy ip_white_list by admin" do
    session[:user_id] = users(:user_one).id
    assert_difference('IpWhiteList.count', -1) do
      delete :destroy, params: { id: @ip_white_list.id}
    end
    assert_redirected_to ip_white_lists_url
  end

  test "should destroy ip_white_list by no-admin" do
    session[:user_id] = users(:user_two).id
    assert_no_difference('IpWhiteList.count', -1) do
      delete :destroy, params: { id: @ip_white_list.id}
    end
    assert_redirected_to error_url
  end

end
