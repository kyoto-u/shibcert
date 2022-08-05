require 'base64'

# ========================================================================
# メール情報アップロード.
class MailController < ApplicationController

  # ----------------------------------------------------------------------
  # 定義.

  # POSTでBasic認証を使う為に認証をオフにする.
  skip_before_action :verify_authenticity_token
  skip_before_action :check_logged_in
  skip_before_action :check_remote_ip

  # Basic認証定義.
  before_action :auth

  BASE64_MAXLEN = 200000
  MAIL_MAXLEN   = 100000

  # ----------------------------------------------------------------------
  # Basic認証実装.
  # パスワードはSHA-1ハッシュ値HEXで覚える.
  def auth
    name = ENV['MAIL_BASIC_AUTH_ID']
    passwd = ENV['MAIL_BASIC_AUTH_PW']
    authenticate_or_request_with_http_basic do |user, pass|
      user == name && pass == passwd
    end
  end

  # ----------------------------------------------------------------------
  # indexはBasic認証の試験用.
  def index
    render plain: 'ok'
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
      render plain: 'error.'
    end
    # DB更新.
    Cert.update_from_mail(update_info)
    render plain: 'done.'
  end

end

# ========================================================================
