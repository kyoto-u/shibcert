require 'test_helper'

class CertsControllerTest < ActionController::TestCase
  setup do
    session[:user_id] = users(:user_one).id
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

  test "post request_post" do
    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s}}
    # テストが並列実行されて、他の Cert が追加されてしまうと、下記のテストは失敗する
    assert_redirected_to request_result_path(Cert.last.id)
  end

  test "post request_post with VLAN-ID" do
    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: "1234"}}
    # テストが並列実行されて、他の Cert が追加されてしまうと、下記のテストは失敗する
    assert_redirected_to request_result_path(Cert.last.id)

    # VLAN-ID の前後に不要な空白を含んでも受け付ける
    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: " 1234 "}}
    assert_redirected_to request_result_path(Cert.last.id)
  end

  test "post request_post with invalid VLAN-ID" do
    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: "ab1234"}}
    assert_redirected_to action: "index"

    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: "1234ab"}}
    assert_redirected_to action: "index"


    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: "ab"}}
    assert_redirected_to action: "index"


    post :request_post, params:{cert: {purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52.to_s,
                                       vlan_id: "12 34"}}
    assert_redirected_to action: "index"

  end


  test "post disable_post" do
    c = certs(:certs_will_revoke)
    post :disable_post, params:{id: c.id}
    assert_redirected_to disable_result_path(c.id)
    assert Cert.find(c.id).state == Cert::State::REVOKE_REQUESTED_TO_NII
  end


  test "post request_post without login" do
    session[:user_id] = nil
    post :request_post
    assert_redirected_to login_url
  end

  test "post disable_post without login" do
    session[:user_id] = nil
    post :disable_post, params:{id: certs(:certs_one).id}
    assert_redirected_to login_url
  end

end
