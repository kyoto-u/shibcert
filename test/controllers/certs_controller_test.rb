require 'test_helper'

class CertsControllerTest < ActionController::TestCase
  setup do
    @cert = certs(:certs_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:certs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cert" do
    assert_difference('Cert.count') do
      post :create, cert: { expire_at: @cert.expire_at, get_at: @cert.get_at, memo: @cert.memo, pin: @cert.pin, pin_get_at: @cert.pin_get_at, user_id: @cert.user_id }
    end

    assert_redirected_to cert_path(assigns(:cert))
  end

  test "should show cert" do
    get :show, id: @cert
    assert_response :success
  end

  test "should post edit_memo_remote" do
    session[:user_id] = users(:users_one).id
    post :edit_memo_remote, params:{cert: {id: certs(:certs_one).id, memo: "change memo"}}
#    post :edit_memo_remote, params: {id: 1, memo: "change memo"}
#    post edit_memo_remote_url(locale:'ja'), params: {id: 1, memo: "change memo"}
#    post edit_memo_remote_url(locale:'ja') + '?id=1', params: {memo: "change memo"}
#    post edit_memo_remote_path(locale:'ja') + '?id=1', params: {memo: "change memo"}
    assert_response :success
  end

  test "should update cert" do
    patch :update, id: @cert, cert: { expire_at: @cert.expire_at, get_at: @cert.get_at, memo: @cert.memo, pin: @cert.pin, pin_get_at: @cert.pin_get_at, user_id: @cert.user_id }
    assert_redirected_to cert_path(assigns(:cert))
  end

  test "should destroy cert" do
    assert_difference('Cert.count', -1) do
      delete :destroy, id: @cert
    end

    assert_redirected_to certs_path
  end
end
