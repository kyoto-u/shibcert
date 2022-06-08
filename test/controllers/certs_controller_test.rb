require 'test_helper'

class CertsControllerTest < ActionController::TestCase
  setup do
    session[:user_id] = users(:users_one).id
#    @cert = certs(:certs_one)
  end

  test "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:certs)
  end

  test "show cert" do
    get :show, params:{id: certs(:certs_one).id}
    assert_response :success
  end

  test "post edit_memo_remote" do
    post :edit_memo_remote, params:{id: certs(:certs_one).id, cert: {memo: "change memo"}}
    assert_response :redirect
  end
end
