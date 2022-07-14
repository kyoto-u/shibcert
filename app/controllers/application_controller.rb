# ========================================================================
# ApplicationController: アプリケーションクラス.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :check_remote_ip
  before_action :set_locale       # ref. http://ruby-rails.hatenadiary.com/entry/20150226/1424937175

  def check_remote_ip
    @remote_ip = request.remote_ip
    return if IpWhiteList.include?(@remote_ip)

    logger.debug("IpWhiteList.include?(#{@remote_ip}) => false")
    if Rails.env.production?
      redirect_to ({controller: :certs, action: :index}), alert: t('ip_white_list.not_allowed_ip')
    else
      logger.debug("check_remote_ip: OK because Rails.env == #{Rails.env}")
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  def default_url_options(options = {})
    {locale: I18n.locale}.merge options
  end

  helper_method :current_user
  private
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
# ========================================================================
