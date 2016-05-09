class SessionsController < ApplicationController
  def create
#    raise request.env["omniauth.auth"].to_yaml

    auth = request.env['omniauth.auth']
    logger.info("#{self}.#{__method__} auth=#{auth.inspect}")
    user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
    logger.info("#{self}.#{__method__} user=#{user.inspect}")
    update_user(user, auth)
    session[:user_id] = user.id
    redirect_to root_url, :notice => 'Signed in!'
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => 'Signed out!'
  end

  private
  def self.update_user(user, auth)
    user[:name]  = auth[:info][:name]
    user[:email] = auth[:info][:email]
    user.save!
  end

end
