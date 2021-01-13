require 'base64'

# ========================================================================
# メール情報アップロード.
class MailController < ApplicationController

  # ----------------------------------------------------------------------
  # 定義.

  # POSTでBasic認証を使う為に事前認証トークン検証をオフにする.
  skip_before_action :verify_authenticity_token

  # Basic認証定義.
  before_action :auth

  BASE64_MAXLEN = 200000
  MAIL_MAXLEN   = 100000

  # ----------------------------------------------------------------------
  # Basic認証実装.
  # パスワードはSHA-1ハッシュ値HEXで覚える.
  def auth
    name = SHIBCERT_CONFIG[Rails.env]['mail_basic_name']
    passwd = SHIBCERT_CONFIG[Rails.env]['mail_basic_pswd']
    authenticate_or_request_with_http_basic do |user, pass|
      user == name && Digest::SHA1.hexdigest(pass) == passwd
    end
  end

  # ----------------------------------------------------------------------
  # indexはBasic認証の試験用.
  def index
    render text: 'ok'
  end

  # ----------------------------------------------------------------------
  # メール受付のメイン処理.
  def processor
    mail = request.body.read(BASE64_MAXLEN)
    body = Base64.decode64(mail)
    mp = MailProcessor.new()
    mp.read_from(StringIO.new(body), MAIL_MAXLEN)
    update_info = mp.get_info
    if update_info == nil
      render text: 'error.'
    end
    # DB更新.
    Cert.update_from_mail(update_info)
    render text: 'done.'
  end

end

# ========================================================================
