#!/usr/bin/env /usr/home/rails/shibcert/bin/rails runner
# coding: utf-8
# Local Variables:
# mode: ruby
# End:

require 'rubygems'
require 'mechanize'
require 'pp'
require 'logger'
require 'csv'
require 'securerandom'
require 'net/https'

# ========================================================================
# RaReq: 電子証明書自動発行支援システム の 発行・更新・失効 申請.
class RaReq

  # ----------------------------------------------------------------------
  # 証明書発行申請.
  module ApplyType
    New = 1
    Renew = 2
    Revoke = 3
  end

  # ----------------------------------------------------------------------
  # 初期化.
  def initialize
    error = false
    %w(admin_name admin_ou admin_mail user_ou).each do |key|
      unless SHIBCERT_CONFIG[Rails.env].has_key?(key)
        Rails.logger.debug "Nesesary value '#{key}' in '#{Rails.env}' is not set in system configuration file."
        error = true
      end
    end
    raise RuntimeError, "System configuration error" if error
  end

  # ----------------------------------------------------------------------
  # 支援システムへの接続.
  def self.get_upload_form
    agent = Mechanize.new
    begin
      agent.cert = SHIBCERT_CONFIG[Rails.env]['certificate_file'] # config/shibcert.yml
    rescue => e
      Rails.logger.info "error: certificate_file '#{SHIBCERT_CONFIG[Rails.env]['certificate_file']}' #{e.inspect}"
      raise
    end
    begin
      agent.key =  SHIBCERT_CONFIG[Rails.env]['certificate_key_file'] # config/shibcert.yml
    rescue => e
      Rails.logger.info "error: certificater_key_file '#{SHIBCERT_CONFIG[Rails.env]['certificate_key_file']}' #{e.inspect}"
      raise
    end
    agent.get('https://scia.secomtrust.net/upki-odcert/lra/SSLLogin.do') # Login with client certificate

    agent.page.frame_with(:name => 'hidari').click

    form = agent.page.form_with(:name => 'MainMenuForm')
    form.forwardName = 'SP1011'     # 「発行・更新・失効」メニューのIDが 'SP1011'

    form2 = form.submit
    form2.form_with(:name => 'SP1011')
  end

  def self.generate_tsv_new(cert)
    user = User.find(cert.user_id)
    raise RuntimeError, "#{__method__} failed: User.find(#{cert.user_id}) == nil" unless user

    pin = ''
    if SHIBCERT_CONFIG['flag']['use_pin_generate'] && cert.download_type == 2
      # P12一括時にPIN指定が可能(オプション)
      pin = SecureRandom.urlsafe_base64
    end

    tsv = [
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
      pin,
    ].join("\t").encode('cp932')

    Rails.logger.debug "#{__method__}: tsv #{tsv.inspect}"
    return tsv
  end

  def self.generate_tsv_renew(cert)
    user = User.find(cert.user_id)
    raise RuntimeError, "#{__method__} failed: User.find(#{cert.user_id}) == nil" unless user

    pin = ''
    if SHIBCERT_CONFIG['flag']['use_pin_generate'] && cert.download_type == 2
      # P12一括時にPIN指定が可能(オプション)
      pin = SecureRandom.urlsafe_base64
    end

    tsv = [
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
      pin,
    ].join("\t").encode('cp932')

    Rails.logger.debug "#{__method__}: tsv #{tsv.inspect}"
    return tsv
  end


  def self.generate_tsv_revoke(cert)
    user = User.find(cert.user_id)
    raise RuntimeError, "#{__method__} failed: User.find(#{cert.user_id}) == nil" unless user

    tsv = [
      cert.dn,                  # 1
      '','',
      cert.serialnumber,         # 4
      cert.revoke_reason || "0", # 5
      cert.revoke_comment,       # 6
      '', '', '',
      SHIBCERT_CONFIG[Rails.env]['admin_mail'], # 管理者(g-certサーバ通知)
      '', '', '',
      user.email,               # 14
      '', # 15:PIN
    ].join("\t").encode('cp932')

    Rails.logger.debug "#{__method__}: tsv #{tsv.inspect}"
    return tsv
  end

  # ----------------------------------------------------------------------
  # 支援システムへの要求TSVファイルのアップロード.
  def self.request(applyType, tsv)
    if Rails.env.test?
      return true
    elsif Rails.env.development?
      File.open("request-#{applyType}-#{Time.now.strftime('%Y%m%d-%H%M%S')}.tsv","w"){|file|
        file.write(tsv)
      }
      return true
    end

    begin
      form = self.get_upload_form

      form.applyType = applyType            # 処理内容 1:発行, 2:更新, 3:失効
      form.radiobuttons_with(:name => 'errorFlg')[0].check # エラーが有れば全件処理を中止
      form.file_upload_with(:name => 'file'){|form_upload| # TSV をアップロード準備
        form_upload.file_data = tsv                        # アップロードする内容を文字列として渡す
        form_upload.file_name = 'sample.tsv'               # 何かファイル名を渡す
        form_upload.mime_type = 'application/force-download' # mime_type これで良いのか？
      }
      submitted_form = form.submit    # submit and file-upload
    rescue Mechanize => e
      Rails.logger.debug "#{__method__}: Mechanize error: ${e.inspect}"
      return false
    end

    if Rails.env == 'development' then
      open("log/last_response.html", "w") do |fp|
        fp.write submitted_form.body.force_encoding("euc-jp")
      end
    end

    if Regexp.new("ファイルのアップロード処理が完了しました。").match(submitted_form.body.encode("utf-8", "euc-jp"))
      Rails.logger.debug "#{__method__}: upload success"
      return true
    else
      Rails.logger.debug "#{__method__}: upload fail"
      filename = "log/cert_#{DateTime.now}_error.html"
      open(filename, "w") do |fp|
        fp.write submitted_form.body.force_encoding("euc-jp")
      end
      return false
    end

  end

  # ----------------------------------------------------------------------
  # UPKI-PASS証明書登録
  def self.upkiPassCert(cert)
    if cert.blank?
      return nil
    end
    return upkiPassUpload(false, cert.pass_pin, cert.pass_p12)
  end
  # 単体試験用
  def self.upkiPassCert2(pin, p12)
    return upkiPassUpload(false, pin, p12)
  end

  # ----------------------------------------------------------------------
  # UPKI-PASS証明書失効
  def self.upkiPassRevoke(cert)
    if cert.blank?
      return nil
    end
    return upkiPassUpload(true, cert.pass_id, nil)
  end
  # 単体試験用
  def self.upkiPassRevoke2(id)
    return upkiPassUpload(true, id, nil)
  end

  # ----------------------------------------------------------------------
  # 内部: UPKI-PASSサーバへのアップロード.
  def self.upkiPassUpload(revoke, arg1, arg2)

    # 設定
    key = ''
    base = SHIBCERT_CONFIG[Rails.env]['upki_pass_url']

    if revoke
      # 失効
      key = SHIBCERT_CONFIG[Rails.env]['upki_pass_key2']
      url = base + "/recvrevocation"
      if arg1.blank?
        Rails.logger.info "RaReq.upkiPass failed because of invalid arg."
        return nil
      end
    else
      # 発行
      key = SHIBCERT_CONFIG[Rails.env]['upki_pass_key1']
      url = base + "/recvcert"
      if arg1.blank? || arg2.blank?
        Rails.logger.info "RaReq.upkiPass failed because of invalid arg."
        return nil
      end
    end

    # http通信設定
    uri = URI.parse(url);
    http = Net::HTTP.new(uri.host, uri.port)
    if url.start_with?("https")
      # HTTPS通信
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE   # とりあえず検証しない
    end
    req = Net::HTTP::Post.new(uri.path)
    if revoke
      req.set_form_data({'key' => key, 'id' => arg1})
    else
      req.set_form_data({'key' => key, 'certfile' => arg1, 'passwdfile' => arg2})
    end

    # http通信実行
    res = http.request(req)

    # 結果確認
    if res.code.to_i != 200
      Rails.logger.info "RaReq.upkiPass failed because of invalid statas:" + res.code
      return "err:" + res.code
    end

    return res.body

  end

  # ----------------------------------------------------------------------
  # 支援システムから全情報TSVファイルのダウンロード.
  def self.requestAll()

    filename = "log/All.tsv"

    agent = Mechanize.new
    begin
      agent.cert = SHIBCERT_CONFIG[Rails.env]['certificate_file'] # config/shibcert.yml
    rescue => e
      Rails.logger.info "error: certificate_file '#{SHIBCERT_CONFIG[Rails.env]['certificate_file']}' #{e.inspect}"
      raise
    end
    begin
      agent.key =  SHIBCERT_CONFIG[Rails.env]['certificate_key_file'] # config/shibcert.yml
    rescue => e
      Rails.logger.info "error: certificater_key_file '#{SHIBCERT_CONFIG[Rails.env]['certificate_key_file']}' #{e.inspect}"
      raise
    end

    # まずログイン.
    agent.get('https://scia.secomtrust.net/upki-odcert/lra/SSLLogin.do')

    # 続いて全情報TSV取得.
    getBody = agent.get('https://scia.secomtrust.net/upki-odcert/lra/syomeiDL_S_Cli.do').body
#    getBody = agent.get('https://scia.secomtrust.net/upki-odcert/lra/riyouDL_S.do').body
    if !getBody
      Rails.logger.debug "#{__method__}: tsv download fail"
      return nil
    end

    # UTF-8に変換.
    body = getBody.encode("UTF-8", "Shift_JIS")
    if body.blank?
      Rails.logger.debug "#{__method__}: tsv is null"
      return nil
    end

    # ファイル保存(後から利用する為)
    open(filename, "w") do |fp|
      fp.write(body)
    end

    # TSVに変換(最初の行はインデックスに利用).
    tsv = CSV.parse(body, col_sep: "\t", headers: :first_row)
    if !tsv
      Rails.logger.debug "#{__method__}: tsv parse fail"
      return nil
    end

#   # 利用例.
#   tsv.each { |line|
#     p line["主体者DN"]
#   }

    return tsv
  end

  # ----------------------------------------------------------------------
  # 取得済み全情報TSVファイルから情報取得
  def self.existAll()

    filename = "log/All.tsv"
    if !File.exist?(filename)
      return nil
    end

    body = nil
    open(filename, "r") do |fp|
      body = fp.read()
    end

    if body.blank?
      Rails.logger.debug "#{__method__}: tsv is null"
      return nil
    end

    # TSVに変換(最初の行はインデックスに利用).
    tsv = CSV.parse(body, col_sep: "\t", headers: :first_row)
    if !tsv
      Rails.logger.debug "#{__method__}: tsv parse fail"
      return nil
    end

    return tsv

  end

  # ----------------------------------------------------------------------
  # 取得済み全情報TSVファイルの削除
  def self.clearAll()

    filename = "log/All.tsv"
    if File.exist?(filename)
      File.delete filename
    end

  end

end

# ========================================================================
# TSVフォーマット仕様.

=begin
# TSV format https://certs.nii.ac.jp/archive/TSV_File_Format/client_tsv/
TSV = [
       'CN=TEST,OU=01,OU=TEST OU,O=NII,L=Tokyo,C=JP', # No.1 certificate DN
       '5',                   # No.2 Profile - 5:client(sha256), 7:S/MIME(sha256)
       '1',                   # No.3 Download Type - 1:P12個別, 2:P12一括, 3:ブラウザ個別
       '',                    # No.4 -
       '',                    # No.5 -
       '',                    # No.6 -
       '',                    # No.7 -
       'Name',                # No.8 admin user name
       'Example OU',          # No.9 admin OU
       'example@example.com', # No.10 admin mail
       'Name',                # No.11 user name
       'example20180321C005', # No.12 P12 filename
       'example OU',          # No.13 user OU
       'example@example.com', # No.14 user mail
       '',                    # No.15 access PIN (not use)
      ].join("\t")
=end

# ========================================================================
# 終了ページの例

=begin

成功例

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>国立情報学研究所 電子証明書自動発行支援システム</title>
</head>

<body>
<table>
    <tr><td arign="center">
    	<img src="/img/submenu_dot.gif"><b>クライアント証明書　発行・更新申請完了画面</b></td></tr>
    <tr><td>&nbsp;</td></tr>
     <tr><td style="position:relative;left:10px">
        ファイルのアップロード処理が完了しました。<br>


        <ul>
        	<li>証明書発行処理が完了後、利用管理者様宛にワンタイムURL付きアクセスPIN取得案内メールを送信致します。</li>
        	<li>利用者様宛にワンタイムURL付き証明書発行案内メールを送信致します。 ワンタイムURLはアクセスPIN取得後、有効化されます。</li>
        	<li>証明書ダウンロードが完了後、登録担当者様と利用管理者様宛にダウンロード完了案内メールを送信致しますのでお待ち下さい。</li>
        </ul>



    </td></tr>
    <tr><td>&nbsp;</td></tr>

    <tr style="position:relative;left:10px;"><td align="center">
        <table border="1" bordercolor="#808080">
            <tr style="background:#AAAAAA">
                <th align="center" nowrap><font size="-1">SEQ</font></th>
                <th align="center" nowrap><font size="-1">処理結果</font></th>
                <th align="center" nowrap><font size="-1">エラー内容</font></th>
                <th align="center" nowrap><font size="-1">機関名</font></th>
                <th align="center" nowrap><font size="-1">所属名</font></th>
                <th align="center" nowrap><font size="-1">氏名</font></th>
                <th align="center" nowrap><font size="-1">メールアドレス</font></th>
            </tr>

            <tr>
	            <td align="center" nowrap><font size="-1">

	            	1
	            </font></td>
	            <td align="center" nowrap><font size="-1">

	            	OK
	            </font></td>
	            <td align="left" nowrap><font size="-1">
	            	&nbsp;

	            </font></td>
	            <td align="left" nowrap><font size="-1">

	            	試験大学
	            </font></td>
	            <td align="left" nowrap><font size="-1">

	            	TEST OU
	            </font></td>
	            <td align="left" nowrap><font size="-1">

	            	Name
	            </font></td>
	            <td align="left" nowrap><font size="-1">

	            	user@example.com
	            </font></td>
	        </tr>

        </table>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
</table>
</body>
</html>
=end

=begin
失敗例

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>国立情報学研究所 電子証明書自動発行支援システム</title>
</head>

<body>
<table>
    <tr><td arign="center">
    	<img src="/img/submenu_dot.gif"><b>クライアント証明書　発行・更新・失効申請エラー画面</b>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
    <tr style="position:relative;left:10px"><td>
                クライアント証明書　発行処理が以下のエラーにより正常終了しませんでした。
    </td></tr>
    <tr><td>&nbsp;</td></tr>
    <tr style="position:relative;left:10px;"><td align="center">
        <table border="1" bordercolor="#808080">
            <tr style="background:#AAAAAA">
                <th align="center" nowrap><font size="-1">SEQ</font></th>
                <th align="center" nowrap><font size="-1">処理結果</font></th>
                <th align="center" nowrap><font size="-1">エラー内容</font></th>
            </tr>

            <tr>
	            <td align="center" nowrap><font size="-1">

	            	1
	            </font></td>
	            <td align="center" nowrap><font size="-1">

	            	NG
	            </font></td>
	            <td align="left" nowrap><font size="-1">

	            	212:1,主体者DN,指定したDNはすでに存在しています。
	            </font></td>
	        </tr>

        </table>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
</table>
</body>
</html>
=end

# ========================================================================
