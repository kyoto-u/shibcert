require 'test_helper'

class RaReqTest < ActiveSupport::TestCase
  test "RaReq.generate_tsv_new" do
    cert = certs(:certs_one)
    user = User.find(cert.user_id)
    expected_tsv = [
      cert.dn,
      cert.purpose_type,
      cert.download_type,   # 1:P12個別 / 2:P12一括(UPKI-PASS)
      '', '', '', '',
      SHIBCERT_CONFIG[Rails.env]['admin_name'],
      SHIBCERT_CONFIG[Rails.env]['admin_ou'],
      SHIBCERT_CONFIG[Rails.env]['admin_mail'],  # 管理者(g-certサーバ通知)
      user.name,
      #        user.number,
      'NIIcert' + Time.now.strftime("%Y%m%d-%H%M%S"),
      SHIBCERT_CONFIG[Rails.env]['user_ou'],
      user.email,
      '',
    ]
    generated_tsv = RaReq.generate_tsv_new(cert).encode('utf-8').split("\t")

    expected_tsv.each_with_index do |v, i|
      next if i == 12           # skip Time.now.strftime("%Y%m%d-%H%M%S")
      assert v.to_s == generated_tsv[i].to_s
    end
  end

  test "RaReq.generate_tsv_renew" do
    cert = certs(:certs_one)
    user = User.find(cert.user_id)
    expected_tsv = [
      cert.dn,
      cert.purpose_type,
      SHIBCERT_CONFIG[Rails.env]['cert_download_type'] || '1', # 1:P12個別
      cert.serialnumber,
      '', '', '',
      SHIBCERT_CONFIG[Rails.env]['admin_name'],
      SHIBCERT_CONFIG[Rails.env]['admin_ou'],
      SHIBCERT_CONFIG[Rails.env]['admin_mail'],  # 管理者(g-certサーバ通知)
      user.name,
      'NIIcert' + Time.now.strftime("%Y%m%d-%H%M%S"),
      SHIBCERT_CONFIG[Rails.env]['user_ou'],
      user.email,
      '',
    ]
    generated_tsv = RaReq.generate_tsv_renew(cert).encode('utf-8').split("\t")

    expected_tsv.each_with_index do |v, i|
      next if i == 12           # skip Time.now.strftime("%Y%m%d-%H%M%S")
      assert v.to_s == generated_tsv[i].to_s
    end
  end

  test "RaReq.generate_tsv_revoke" do
    cert = certs(:certs_one)
    user = User.find(cert.user_id)
    expected_tsv = [
      cert.dn,                  # 1
      '','',
      cert.serialnumber,         # 4
      cert.revoke_reason || "0", # 5
      cert.revoke_comment,       # 6
      '', '', '',
      SHIBCERT_CONFIG[Rails.env]['admin_mail'], # 管理者(g-certサーバ通知)
      '', '', '',
      user.email,               # 14
      '',                       # 15:PIN
    ]
    generated_tsv = RaReq.generate_tsv_revoke(cert).encode('utf-8').split("\t")

    expected_tsv.each_with_index do |v, i|
      next if i == 12           # skip Time.now.strftime("%Y%m%d-%H%M%S")
      assert v.to_s == generated_tsv[i].to_s
    end
  end

end
