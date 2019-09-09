# ========================================================================
# SessionsController: 認証セッションクラス.
class SessionsController < ApplicationController

  # ----------------------------------------------------------------------
  # 生成.
  def create
#    raise request.env["omniauth.auth"].to_yaml

    auth = request.env['omniauth.auth']
    logger.info("#{self}.#{__method__} auth=#{auth.inspect}")
    user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
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
    number = auth[:info][:number]
    if number == nil
      number = auth['uid']
    end
    printable = number.gsub!(/@+|\(+|\)+|'+|:+|\/+|\.+|=+|_+/, '-') 
    if printable != nil
      number = printable
    end
    user[:number] = number
    user.save!
  end

end

# ========================================================================
