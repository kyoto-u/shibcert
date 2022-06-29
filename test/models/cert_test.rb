require 'test_helper'

class CertTest < ActiveSupport::TestCase

  test "PurposeType 5 is CLIENT_AUTH" do
    assert Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52 == 5
    assert Cert.is_client_auth(Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52)
  end
  test "PurposeType 13 is CLIENT_AUTH" do
    assert Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_13 == 13
    assert Cert.is_client_auth(Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_13)
  end
  test "PurposeType 14 is CLIENT_AUTH" do
    assert Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_25 == 14
    assert Cert.is_client_auth(Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_25)
  end

  test "PurposeType 7 is S/MIME" do
    assert Cert::PurposeType::SMIME_CERTIFICATE_52 == 7
    assert Cert.is_smime(Cert::PurposeType::SMIME_CERTIFICATE_52)
  end
  test "PurposeType 15 is S/MIME" do
    assert Cert::PurposeType::SMIME_CERTIFICATE_13 == 15
    assert Cert.is_smime(Cert::PurposeType::SMIME_CERTIFICATE_13)
  end
  test "PurposeType 16 is S/MIME" do
    assert Cert::PurposeType::SMIME_CERTIFICATE_25 == 16
    assert Cert.is_smime(Cert::PurposeType::SMIME_CERTIFICATE_25)
  end

  test "Cert#set_attributes works for S/MIME certificate" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::SMIME_CERTIFICATE_13}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1@mail.com.0.' + SHIBCERT_CONFIG['test']['base_dn_dev'] + ',' + SHIBCERT_CONFIG['test']['base_dn_smime']
  end

  test "Cert#set_attributes works for client auth certificate" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid.0.' + SHIBCERT_CONFIG['test']['base_dn_dev'] + ',' + SHIBCERT_CONFIG['test']['base_dn_auth']
  end

  test "Cert#set_attributes works for client auth certificate with VLAN-ID" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "vlan_id" => "1234"}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid@1234.0.' + SHIBCERT_CONFIG['test']['base_dn_dev'] + ',' + SHIBCERT_CONFIG['test']['base_dn_auth']
  end

  test "Cert#set_attributes works for client auth certificate with empty VLAN-ID" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "vlan_id" => ""}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid.0.' + SHIBCERT_CONFIG['test']['base_dn_dev'] + ',' + SHIBCERT_CONFIG['test']['base_dn_auth']
  end

  test "Cert#set_attributes works for UPKI-pass certificate" do
    c = Cert.new
    pass_id = "PASSID"
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "pass_opt" => "1", "pass_id" => pass_id}}
    c.set_attributes(params, user: users(:users_one))
    assert c.download_type == 2
    assert c.pass_id == pass_id
    assert c.dn == "CN=#{pass_id} user1 name.0." + SHIBCERT_CONFIG['test']['base_dn_dev'] + ',' + SHIBCERT_CONFIG['test']['base_dn_auth']
  end

  test "Cert#next_state works for NEW_*" do
    c = Cert.new
    c.state = Cert::State::NEW_REQUESTED_FROM_USER
    assert c.next_state == Cert::State::NEW_REQUESTED_TO_NII
    assert c.next_state == Cert::State::NEW_RECEIVED_MAIL
    assert c.next_state == Cert::State::NEW_GOT_PIN
    assert c.next_state == Cert::State::NEW_DISPLAYED_PIN
    assert c.next_state == Cert::State::NEW_GOT_SERIAL
    assert_raises RuntimeError do
      c.next_state
    end

    c.state = Cert::State::NEW_ERROR
    assert_raises RuntimeError do
      c.next_state
    end
  end

  test "Cert#next_state works for RENEW_*" do
    c = Cert.new
    c.state = Cert::State::RENEW_REQUESTED_FROM_USER
    assert c.next_state == Cert::State::RENEW_REQUESTED_TO_NII
    assert c.next_state == Cert::State::RENEW_RECEIVED_MAIL
    assert c.next_state == Cert::State::RENEW_GOT_PIN
    assert c.next_state == Cert::State::RENEW_DISPLAYED_PIN
    assert c.next_state == Cert::State::RENEW_GOT_SERIAL
    assert_raises RuntimeError do
      c.next_state
    end

    c.state = Cert::State::RENEW_ERROR
    assert_raises RuntimeError do
      c.next_state
    end
  end

  test "Cert#next_state works for REVOKE_*" do
    c = Cert.new
    c.state = Cert::State::REVOKE_REQUESTED_FROM_USER
    assert c.next_state == Cert::State::REVOKE_REQUESTED_TO_NII
    assert c.next_state == Cert::State::REVOKE_RECEIVED_MAIL
    assert c.next_state == Cert::State::REVOKED
    assert_raises RuntimeError do
      c.next_state
    end

    c.state = Cert::State::REVOKE_ERROR
    assert_raises RuntimeError do
      c.next_state
    end
  end

  test "Cert#set_error_state for NEW*" do
    c = Cert.new

    c.state = Cert::State::NEW_REQUESTED_FROM_USER
    assert c.set_error_state == Cert::State::NEW_ERROR

    c.state = Cert::State::NEW_RECEIVED_MAIL
    assert c.set_error_state == Cert::State::NEW_ERROR

    c.state = Cert::State::NEW_ERROR
    assert c.set_error_state == Cert::State::NEW_ERROR
  end

  test "Cert#set_error_state for RENEW*" do
    c = Cert.new

    c.state = Cert::State::RENEW_REQUESTED_FROM_USER
    assert c.set_error_state == Cert::State::RENEW_ERROR

    c.state = Cert::State::RENEW_RECEIVED_MAIL
    assert c.set_error_state == Cert::State::RENEW_ERROR

    c.state = Cert::State::RENEW_ERROR
    assert c.set_error_state == Cert::State::RENEW_ERROR
  end

  test "Cert#set_error_state for REVOKE*" do
    c = Cert.new

    c.state = Cert::State::REVOKE_REQUESTED_FROM_USER
    assert c.set_error_state == Cert::State::REVOKE_ERROR

    c.state = Cert::State::REVOKE_RECEIVED_MAIL
    assert c.set_error_state == Cert::State::REVOKE_ERROR

    c.state = Cert::State::REVOKE_ERROR
    assert c.set_error_state == Cert::State::REVOKE_ERROR
  end

end
