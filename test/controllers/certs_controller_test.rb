require 'test_helper'

class CertsControllerTest < ActionController::TestCase
  setup do
    session[:user_id] = users(:users_one).id
#    @cert = certs(:certs_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:certs)
  end

  test "should show cert" do
    get :show, id: @cert
    assert_response :success
  end

  test "should post edit_memo_remote" do
    post :edit_memo_remote, params:{id: certs(:certs_one).id, cert: {memo: "change memo"}}
    assert_response :redirect
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
