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
    assert c.dn == 'CN=user1@mail.com,OU=No 0,OU=test,OU=Institute for Information Management and Communication,O=Kyoto University,ST=Kyoto,C=JP'
  end

  test "Cert#set_attributes works for client auth certificate" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid,OU=No 0,OU=test,OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP'
  end

  test "Cert#set_attributes works for client auth certificate with VLAN-ID" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "vlan_id" => "1234"}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid@1234,OU=No 0,OU=test,OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP'
  end

  test "Cert#set_attributes works for client auth certificate with empty VLAN-ID" do
    c = Cert.new
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "vlan_id" => ""}}
    c.set_attributes(params, user: users(:users_one))
    assert c.dn == 'CN=user1uid,OU=No 0,OU=test,OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP'
  end

  test "Cert#set_attributes works for UPKI-pass certificate" do
    c = Cert.new
    pass_id = "PASSID"
    params = {cert: {"purpose_type" => Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52, "pass_opt" => "1", "pass_id" => pass_id}}
    c.set_attributes(params, user: users(:users_one))
    assert c.download_type == 2
    assert c.pass_id == pass_id
    assert c.dn == "CN=#{pass_id} user1 name,OU=No 0,OU=test,OU=Kyoto University Integrated Information Network System,O=Kyoto University,ST=Kyoto,C=JP"
  end

end
