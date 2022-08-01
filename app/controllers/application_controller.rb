# ========================================================================
# ApplicationController: アプリケーションクラス.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :check_logged_in
  before_action :check_remote_ip
  before_action :set_locale       # ref. http://ruby-rails.hatenadiary.com/entry/20150226/1424937175

  def check_logged_in
    if current_user.nil?
      return redirect_to controller: :sessions, action: :new
    end
  end

  def check_remote_ip
    # session[:kuMfaEnabled] type is unknown 0/1, true/false or "TRUE"/"FALSE"
    if session[:kuMfaEnabled] == "TRUE"
      logger.info("#{__method__}: kuMfaEnabled == true, skip remote_ip check.")
      return
    end
    @remote_ip = request.remote_ip
    return if IpWhiteList.include?(@remote_ip)

    logger.info("#{__method__}: IpWhiteList.include?(#{@remote_ip}) => false")
    unless Rails.env.production?
      if ['0.0.0.0', '127.0.0.1', '::1'].include?(@remote_ip)
        logger.debug("#{__method__}: allow localhost on #{Rails.env} mode")
        return
      end
    end
    redirect_to ({controller: :sessions, action: :new}), alert: t('ip_white_list.not_allowed_ip')
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
