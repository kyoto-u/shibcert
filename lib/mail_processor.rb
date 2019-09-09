#!/usr/bin/env /usr/home/rails/shibcert/bin/rails runner
# coding: utf-8
# Local Variables:
# mode: ruby
# End:

require 'rubygems'
require 'mechanize'
require 'mail'
require 'zipruby'
require 'pp'
require 'logger'
require 'base64'

# ========================================================================
# MailProcessor: 電子証明書自動発行支援システム から送られたメールの解析.
# Note: メール書式が変更された場合には本クラスも修正が必要.
class MailProcessor

  # ----------------------------------------------------------------------
  # メンバ.
  @mail = nil
  
  # ----------------------------------------------------------------------
  # 初期化.
  def initialize()
    # ログファイルの準備.
    @logger = Logger.new('log/mail_processor.log')
    @logger.progname = "#{$0}[#{$$}]"
    @logger.info("start")
    @logger.info("Process.(uid,euid)=(#{Process.uid},#{Process.euid})")
    @logger.info("Rails.env=#{Rails.env}")
  end

  # ----------------------------------------------------------------------
  # メール読み込み.
  def read_from(stream, maxlen=50000)
    mail_eml = stream.read(maxlen)
    if mail_eml.size >= maxlen
      @logger.info("exit: too large mail (>#{maxlen.to_s})")
      exit
    end
    @logger.info("debug: size = " + mail_eml.size.to_s)
    @mail = Mail.read_from_string(mail_eml)
    unless @mail.from == ['ca-support@ml.secom-sts.co.jp']
      @logger.info("exit: skip From: #{@mail.from}")
      exit
    end

    unless @mail.parts[1].content_type == 'application/pkcs7-signature; name=smime.p7s; smime-type=signed-data'
      @logger.info("exit: no digital signature found")
      exit
    end
  end

  # ----------------------------------------------------------------------
  # メールから情報取得.
  def get_info
    unless @mail
      @logger.error("no mail content")
      return nil
    end

    subject = @mail.subject.split(" /")[0]
    @logger.info("subject = " + @mail.subject)
#puts @mail.subject

#    case @mail.subject
    case subject
    when '[UPKI] アクセスPIN発行通知'
      @logger.info("mail type: access PIN")
      self.get_pin
    when '[UPKI] クライアント証明書取得通知'
      @logger.info("mail type: serial number")
      self.get_serial
    when '[UPKI] クライアント証明書失効完了通知'
      @logger.info("mail type: revoked")
      self.get_revoked_serial
    when '[UPKI] クライアント証明書失効完了通知 / [UPKI] client cerompletion notification'
      @logger.info("mail type: revoked2")
      self.get_revoked_serial
    when '[UPKI] クライアント証明書更新通知'
      @logger.info("mail type: renew serial")
      self.get_renew_serial
    when '[UPKI] クライアント証明書発行受付通知'
      @logger.info("mail type: upki-pass file")
      self.get_upki_pass_file
    when '[UPKI] クライアント証明書発行受付通知 / [UPKI] client certificate issue acceptance notice'
      @logger.info("mail type: upki-pass file2")
      self.get_upki_pass_file
    else
      @logger.info("mail type: unknown, exit")
      return nil
    end
  end

  # ----------------------------------------------------------------------
  # PIN情報取得: [UPKI] アクセスPIN発行通知.
  def get_pin
    # メールチェック.
    unless @mail
      @logger.error("get_pin: no mail info")
      return nil
    end

    # ダウンロードURL取得.
    url = @mail.text_part.decoded.match(/https:\/\/scia.secomtrust.net\/[-=%\.\/\?\w]+/)
    @logger.info("URL: #{url}")

    # URLからUPKI-PASS(P12個別)かどうかの判定
    if url.to_s.include?("SPEntranceCliAllPin.jsp")
      @logger.info('UPKI-PASS URL')
      upki_pass = true
      download_address1 = '/upki-odcert/download/spEntranceCliAllPin.do'
      download_address2 = '/upki-odcert/download/spDLCliAllPin.do'
    else
      @logger.info("CLIENT URL")
      upki_pass = false
      download_address1 = '/upki-odcert/download/spEntranceCliPin.do'
      download_address2 = '/upki-odcert/download/spDLCliPin.do'
    end

    # 取得.
    agent = Mechanize.new

    # PINのZIPファイルダウンロードアドレスの取得.
    page = agent.get(url)
    unless page.form_with
      @logger.info('mechanize: error stop, no form with spEntranceCliPin.do')
      return nil
    end
    page = page.form_with(:action => download_address1).submit

    # PINのZIPファイルのダウンロード.
    unless page.form_with
      @logger.info('mechanize: error stop, no form with spDLCliPin.do')
      return nil
    end
    page = page.form_with(:action => download_address2).submit

    # ダウンロードしたZIPファイルの処理.
    zipstream = page.body       # ZIP binary
    @logger.info("zipstream: #{zipstream.inspect}")
    if upki_pass
      @logger.info("UPKI-PASS PIN")
      b64pin = Base64.strict_encode64(zipstream)
#      if Rails.env == 'development' then
#        open("log/allPin.b64", "w") do |fp|
#          fp.write(b64pin)
#        end
#      end
      Zip::Archive.open_buffer(zipstream) do |ar|
        ar.each do |f|
          # 1PINのみ読み込み.
          record = f.read.split("\n")[1] # 2nd line
          name, email, pin, dn = record.split("\t")[0..3]
          @logger.info("PIN: #{pin} for #{dn}, name #{name}, email #{email}")
          return {update_target: 'upasspin', value: b64pin, dn: dn, name: name, serial: nil}
        end
      end
    else
      @logger.info("CLIENT PIN")
      Zip::Archive.open_buffer(zipstream) do |ar|
        ar.each do |f|
          # 1PINのみ読み込み.
          record = f.read.split("\n")[1] # 2nd line
          name, email, pin, dn = record.split("\t")[0..3]
#          pin, dn = record.split("\t")[2,3]
          @logger.info("PIN: #{pin} for #{dn}")
          return {update_target: 'pin', value: pin, dn: dn, name: name, serial: nil}
        end
      end
    end

    @logger.info("PIN: not found")
    return nil
  end

  # ----------------------------------------------------------------------
  # UPKI-PASSファイル取得: [UPKI] クライアント証明書発行受付通知
  def get_upki_pass_file
    # メールチェック.
    unless @mail
      @logger.error("get_upki_pass_file: no mail info")
      return nil
    end

    # 2分待つ(PIN取得が先じゃないとダウンロードできない為)
    # PINとファイルのメールは同時に送信されるので2分で充分のはず
    sleep 120

    # ダウンロードURL取得.
    url = @mail.text_part.decoded.match(/https:\/\/scia.secomtrust.net\/[-=%\.\/\?\w]+/)
    @logger.info("URL: #{url}")

    # ダウンロードアドレス
    download_address1 = '/upki-odcert/download/spEntranceCliAll.do'
    download_address2 = '/upki-odcert/download/spDLCliAll.do'

    # 取得.
    agent = Mechanize.new

    # PINのZIPファイルダウンロードアドレスの取得.
    page = agent.get(url)
    unless page.form_with
      @logger.info('mechanize: error stop, no form with spEntranceCliAll.do')
      return nil
    end
    page = page.form_with(:action => download_address1).submit

    # PINのZIPファイルのダウンロード.
    unless page.form_with
      @logger.info('mechanize: error stop, no form with spDLCliAll.do')
      return nil
    end
    page = page.form_with(:action => download_address2).submit

    # ダウンロードしたZIPファイルの処理.
    zipstream = page.body       # ZIP binary
    @logger.info("zipstream: #{zipstream.inspect}")
    b64file = Base64.strict_encode64(zipstream)
#    if Rails.env == 'development' then
#      open("log/all.b64", "w") do |fp|
#        fp.write(b64file)
#      end
#    end
    Zip::Archive.open_buffer(zipstream) do |ar|
      ar.each do |f|
        if f.name == "client.txt"
          # 1行のみ読み込み.
          record = f.read.split("\n")[1] # 2nd line
          serial, name, email, dn = record.split("\t")[0..3]
          @logger.info("SERIAL: #{serial} for #{dn}, name #{name}, email #{email}")
          return {update_target: 'upassfile', value: b64file, dn: dn, name: name, serial: serial}
        end
      end
    end

  end
 
  # ----------------------------------------------------------------------
  # シリアル番号他取得: [UPKI] クライアント証明書取得通知.
  def get_serial
    # メールチェック.
    unless @mail
      @logger.error("get_serial: no mail info")
      return nil
    end

=begin

Subject: [UPKI] クライアント証明書取得通知

【対象証明書DN】
　---------------------------------------------
　CN=gcert000
　OU=001
　OU=UPKI Client Cert Enrollment System Develop
　O=National Institute of Informatics
　L=Tokyo
　C=JP
　---------------------------------------------

【対象証明書シリアル番号】
　4097000000000000000

=end

    # 対象証明書のDN情報取得.
    mail_text_part = @mail.text_part.decoded
    mail_text_part.match(/^【対象証明書DN】\n　---------------------------------------------\n(.*)\n　---------------------------------------------$/m)
    dn = Regexp.last_match(1).delete('　').split("\n").join(',')

    # 対象証明書のシリアル番号取得.
    mail_text_part.match(/^【対象証明書シリアル番号】\n　(\d+)$/m)
    serial = Regexp.last_match(1)
    if serial
      # シリアル番号があった.
      @logger.info("serial: #{serial} for #{dn}")
      return {update_target: 'x509_serialnumber', value: serial, dn: dn, name: nil, serial: serial}
    else
      @logger.info("serial: not found")
      return nil
    end
  end

  # ----------------------------------------------------------------------
  # シリアル番号他取得: [UPKI] クライアント証明書更新通知.
  def get_renew_serial
    # メールチェック.
    unless @mail
      @logger.error("get_serial: no mail info")
      return nil
    end

=begin

Subject: [UPKI] クライアント証明書更新通知

【対象証明書DN】
　---------------------------------------------
　CN=gcert000
　OU=001
　OU=UPKI Client Cert Enrollment System Develop
　O=National Institute of Informatics
　L=Tokyo
　C=JP
　---------------------------------------------

【新証明書シリアル番号】
　6967484703334057720

【旧証明書のシリアル番号】
　539235709030798470

=end

    # 対象証明書のDN情報取得.
    mail_text_part = @mail.text_part.decoded
    mail_text_part.match(/^【対象証明書DN】\n　---------------------------------------------\n(.*)\n　---------------------------------------------$/m)
    dn = Regexp.last_match(1).delete('　').split("\n").join(',')

    # 対象証明書のシリアル番号取得.
    mail_text_part.match(/^【新証明書シリアル番号】\n　(\d+)$/m)
    serial = Regexp.last_match(1)
    if serial
      # シリアル番号があった.
      @logger.info("serial: #{serial} for #{dn}")
      return {update_target: 'x509_serialnumber', value: serial, dn: dn, name: nil, serial: serial}
    else
      @logger.info("serial: not found")
      return nil
    end
  end

  # ----------------------------------------------------------------------
  # 失効情報取得: [UPKI] クライアント証明書失効完了通知,
  def get_revoked_serial
    # メールチェック.
    unless @mail
      @logger.error("get_revoked_serial: no mail info")
      return nil
    end

    # 失効証明書のDN情報取得.
    mail_text_part = @mail.text_part.decoded
    m = mail_text_part.match(/このメールに心当たりがない場合や不明点等ございましたら、/)
    mail_text_part2 = m.pre_match
    mail_text_part2.match(/^【失効証明書DN】\n　---------------------------------------------\n(.*)\n　---------------------------------------------$/m)
    dn = Regexp.last_match(1).delete('　').split("\n").join(',')

    # 失効証明書のシリアル番号取得.
    mail_text_part.match(/^【失効証明書シリアル番号】\n　(\d+)$/m)
    serial = Regexp.last_match(1)
    if serial
      # シリアル番号があった.
      @logger.info("revoked_serial: #{serial} for #{dn}")
      return {update_target: 'revoked_x509_serialnumber', value: serial, dn: dn, name: nil, serial: nil}
    else
      @logger.info("revoked_serial: not found")
      return nil
    end
  end

end

# ========================================================================
# コマンド実行部: scripts/mail_processor_caller.sh からの呼び出し.
if $0 == __FILE__ then
  MAIL_MAXLEN = 100000
  mp = MailProcessor.new()
#  mp.read_from(ARGF, MAIL_MAXLEN)
  mp.read_from(STDIN, MAIL_MAXLEN)
  update_info = mp.get_info
  if update_info != nil
#    puts update_info
    Cert.update_from_mail(update_info)
  else
    puts "Error."
  end
end

# ========================================================================
