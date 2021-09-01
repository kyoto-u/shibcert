# coding: utf-8
# ========================================================================
# SessionsController: 認証セッションクラス.
# protect_from_forgery の設定を分けるため ApplicationController ではなく
# ActionController::Base を継承
class SessionsController < ActionController::Base
  protect_from_forgery except: [:create], with: :exception

  # ----------------------------------------------------------------------
  # 生成.
  def create
#    raise request.env["omniauth.auth"].to_yaml

    auth = request.env['omniauth.auth']
    provider = auth[:provider]
    if Rails.env.production? && provider == 'identity'
      logger.info("ignore: access to identity in production mode")
      redirect_to root_url
    end
    logger.debug("#{self}.#{__method__} auth=#{auth.inspect}")
    uid = case provider
          when 'identity'
            Identity.find(auth[:uid])[:uid]
          when 'saml'
            auth[:info][:uid]
          else
            auth[:uid]
          end

    logger.info("#{self}.#{__method__} provider:#{provider},uid:#{uid}")

    user = User.find_by(provider: provider, uid: uid) || User.create_with_omniauth(auth)
    logger.info("#{self}.#{__method__} user=#{user.inspect}")
    update_user(user, auth)
    session[:user_id] = user.id
    Cert.update_from_login(user.id)
    redirect_to root_url, :notice => 'Signed in!'
  end

  # ----------------------------------------------------------------------
  # 削除.
  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, alert: "Authentication failed."
  end

  # ----------------------------------------------------------------------
  # 更新.
  private
  def update_user(user, auth)
    user[:name]  = auth[:info][:name]
    user[:email] = auth[:info][:email]
    number = auth[:info][:number] || user[:uid]
    printable_number = number.gsub!(/@+|\(+|\)+|'+|:+|\/+|\.+|=+|_+/, '-')
    user[:number] = printable_number || number
    user.save!
  end

end

# ========================================================================
