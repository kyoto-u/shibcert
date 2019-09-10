# coding: utf-8

require 'base64'

# ========================================================================
# 管理者クラス.
class AdminController < ApplicationController

  skip_before_action :verify_authenticity_token

  # Basic認証定義.
  before_filter :auth

  # ----------------------------------------------------------------------
  # Basic認証実装.
  # パスワードはSHA-1ハッシュ値HEXで覚える.
  def auth
    name = SHIBCERT_CONFIG[Rails.env]['admin_basic_name']
    passwd = SHIBCERT_CONFIG[Rails.env]['admin_basic_pswd']
    authenticate_or_request_with_http_basic do |user, pass|
      user == name && Digest::SHA1.hexdigest(pass) == passwd
    end
  end

  # ----------------------------------------------------------------------
  # トップ画面.
  def index

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    # ページングサイズ
    limit = SHIBCERT_CONFIG['flag']['admin_page_num']

    # 初期設定
    @uid_ck = false
    @name_ck = false
    @mail_ck = false
    @totop = false

    if params[:key].blank?
      # 全て: ページング
      @uid_ck = true
      count = User.count
      if count <= 0
        errorMesg('No user.')
        return
      end
      @page_max = count / limit
      if @page_max * limit != count
        @page_max += 1
      end
      @page_num = params[:page] == nil ? 1 : params[:page].to_i
      if @page_num < 1
        @page_num = 1
      elsif @page_num > @page_max
        @page_num = @page_max
      end
      if @page_num > 1
        @totop = true
      end
      @users = User.all.order("updated_at DESC").limit(limit).offset(limit*(@page_num-1))
      @search_num = @users.length
    else
      # 検索
      @key = params[:key]
      if params[:admin][:opt] == "uid"
        item = "uid"
        @uid_ck = true
      elsif params[:admin][:opt] == "name"
        item = "name"
        @name_ck = true
      else
        item = "email"
        @mail_ck = true
      end
      @page_max = 0
      @page_num = 0
      @users = User.where(item + " like '%" + params[:key] + "%'").order("updated_at DESC")
      @search_num = @users.length
      if @search_num > limit
        @users.slice!(limit-1..@search_num-limit)
      end
    end

  end

  # ----------------------------------------------------------------------
  # ユーザ情報.
  def user

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    # 引数確認
    if params[:id].blank?
      errorMesg('Argument error.')
      return
    end

    # ユーザ検索
    @user = User.find_by_id(params[:id])
    if @user.blank?
      errorMesg('Search user error (' + params[:id] + ').')
      return
    end

    # 証明書情報
    @certs = Cert.where(user_id: @user.id).order("created_at DESC")

  end

  # ----------------------------------------------------------------------
  # 証明書情報.
  def cert

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    # 引数確認
    if params[:id].blank?
      errorMesg('Argument error.')
      return
    end

    # 証明書情報
    @cert = Cert.find_by_id(params[:id])
    if @cert.blank?
      errorMesg('Search certificate error (' + params[:id] + ').')
      return
    end

  end

  # ----------------------------------------------------------------------
  # TSV解析
  def parseTsv(tsv)

    tsvs = { wait:[], issue:[], update:[], revoke:[], error:[] }
    tsv.each { |cert|
      # TSV情報解析
      if !cert["発行・更新申請-シリアル番号"].blank?
        mycert = Cert.find_by_serialnumber(cert["発行・更新申請-シリアル番号"])
      end
      if mycert.blank? && !cert["主体者DN"].blank?
        mycert = Cert.find_by_dn(cert["主体者DN"])
      end
      if !mycert.blank?
        cert["DB登録"] = "登録済み"
      end
      case cert["状態"].to_i
      when 4 then
        tsvs[:wait].push cert
      when 5 then
        tsvs[:issue].push cert
      when 6 then
        tsvs[:update].push cert
      when 7 then
        tsvs[:revoke].push cert
      else
        tsvs[:error].push cert
      end
    }

    return tsvs

  end

  # ----------------------------------------------------------------------
  # NIIサーバ同期.
  def sync

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    # TSVファイル取得
    tsv = RaReq.requestAll();
    if tsv.blank?
      errorMesg('Download server certificate info error.')
      return
    end

    # TSV解析
    @tsvs = parseTsv(tsv)
    if @tsvs.blank?
      errorMesg('Download server certificate info parse error.')
      return
    end

    # カウント
    @count = tsv.length
    @upcount = (@tsvs[:wait].select {|val| val["DB登録"] == "登録済み" }).length \
             + (@tsvs[:issue].select {|val| val["DB登録"] == "登録済み" }).length \
             + (@tsvs[:update].select {|val| val["DB登録"] == "登録済み" }).length \
             + (@tsvs[:revoke].select {|val| val["DB登録"] == "登録済み" }).length \
             + (@tsvs[:error].select {|val| val["DB登録"] == "登録済み" }).length

  end

  # ----------------------------------------------------------------------
  # 取得証明書の表示.
  def show

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    # 情報取得(ファイルから)
    tsv = RaReq.existAll();
    if tsv.blank?
      errorMesg('Download server certificate info error.')
      return
    end

    # TSV解析
    tsvs = parseTsv(tsv)
    if tsvs.blank?
      errorMesg('Download server certificate info parse error.')
      return
    end

    # 種別
    type = 0
    @type_name = "unknown"
    if !params[:type].blank?
      type = params[:type].to_i
    end

    # セット
    @certs = []
    case type
    when 4 then
        @type_name = t('admin.sync.wait')
        @certs = tsvs[:wait]
    when 5 then
        @type_name = t('admin.sync.issue')
        @certs = tsvs[:issue]
    when 6 then
        @type_name = t('admin.sync.update')
        @certs = tsvs[:update]
    when 7 then
        @type_name = t('admin.sync.revoke')
        @certs = tsvs[:revoke]
    else
        @type_name = t('admin.sync.error')
        @certs = tsvs[:error]
    end

  end

  # ----------------------------------------------------------------------
  # DB登録実行
  def db_update(certs)
    # ToDo
    return certs.length
  end

  # ----------------------------------------------------------------------
  # 取得証明書のDB反映
  def update_post

    if !current_user
      return redirect_to :action => "index"
    end

#    flash[:alert] = "revoke error"
#    redirect_to :action => "cert" and return

    # 情報取得(ファイルから)
    tsv = RaReq.existAll();
    if tsv.blank?
      flash[:alert] = 'Download server certificate info error.'
      redirect_to :action => "cert" and return
    end

    # TSV解析
    tsvs = parseTsv(tsv)
    if tsvs.blank?
      flash[:alert] = 'Download server certificate info parse error.'
      redirect_to :action => "cert" and return
    end

    count = 0;

    # 取得待ち
    if params[:import][:wait_new] != "0"
      certs = tsvs[:wait].select {|val| val["DB登録"] != "登録済み" }
      num = db_update(certs)
      count += num
    end
    if params[:import][:wait_exist] != "0"
      certs = tsvs[:wait].select {|val| val["DB登録"] == "登録済み" }
      num = db_update(certs)
      count += num
    end

    # 発行済み
    if params[:import][:issue_new] != "0"
      certs = tsvs[:issue].select {|val| val["DB登録"] != "登録済み" }
      num = db_update(certs)
      count += num
    end
    if params[:import][:issue_exist] != "0"
      certs = tsvs[:issue].select {|val| val["DB登録"] == "登録済み" }
      num = db_update(certs)
      count += num
    end

    # 更新済み
    if params[:import][:update_new] != "0"
      certs = tsvs[:update].select {|val| val["DB登録"] != "登録済み" }
      num = db_update(certs)
      count += num
    end
    if params[:import][:update_exist] != "0"
      certs = tsvs[:update].select {|val| val["DB登録"] == "登録済み" }
      num = db_update(certs)
      count += num
    end

    # 失効済み
    if params[:import][:revoke_new] != "0"
      certs = tsvs[:revoke].select {|val| val["DB登録"] != "登録済み" }
      num = db_update(certs)
      count += num
    end
    if params[:import][:revoke_exist] != "0"
      certs = tsvs[:revoke].select {|val| val["DB登録"] == "登録済み" }
      num = db_update(certs)
      count += num
    end

    # エラー
    if params[:import][:error_new] != "0"
      certs = tsvs[:error].select {|val| val["DB登録"] != "登録済み" }
      num = db_update(certs)
      count += num
    end
    if params[:import][:error_exist] != "0"
      certs = tsvs[:error].select {|val| val["DB登録"] == "登録済み" }
      num = db_update(certs)
      count += num
    end

    # DB登録処理結果
    if count > 0
      flash[:notice] = "DataBase Updated (" + count.to_s + ") Certificates."
    else
      flash[:alert] = "DataBase No Updated (may be not seleced)."
    end

    # 取得ファイルの削除
    RaReq.clearAll();

    # 管理者トップ画面に戻る
    redirect_to :action => "index"

  end

  # ----------------------------------------------------------------------
  # 取得証明書の表示.
  def clear

    if !current_user
      return redirect_to :action => "index"
    end

    # 取得ファイルの削除
    RaReq.clearAll();

    # 管理者トップ画面に戻る
    redirect_to :action => "index"

  end

  # ----------------------------------------------------------------------
  # 証明書エラー表示.
  def error

    if !current_user
      return redirect_to controller: :certs, :action => "index"
    end

    if params[:id].blank?
      errorMesg('cert_id undefined.')
      return
    end

#    errorMesg('error test.')
#    return

    # 証明書エラーファイルの確認
    html = nil
    filename = "log/cert_" + params[:id] + "_error.html"
    if !File.exist?(filename)
      errorMesg('cert_error_file not found.')
      return
    end

    # 証明書エラーファイルの読み込み
    open(filename) do |fp|
      html = fp.read
    end
    if html.blank?
      errorMesg('cert_error_file cannot read.')
      return
    end

    # HTML表示
    send_data html, type: 'text/html', disposition: :inline

  end

  # ----------------------------------------------------------------------
  # エラー表示.
  def errorMesg(mesg)
    @mesg = mesg.html_safe if !mesg.blank?
    render action: 'errorMesg'
  end

  # ----------------------------------------------------------------------
  # 失効申請
  def disable_post

    if !current_user
      return redirect_to :action => "index"
    end

#    flash[:alert] = "revoke error"
#    redirect_to :action => "cert" and return

    if params[:id].blank?
      flash[:alert] = "cert_id undefined."
      redirect_to :action => "cert" and return
    end

    # 証明書取得
    @cert = Cert.find_by_id(params[:id])
    if @cert.blank?
      flash[:alert] = "cert undefined."
      redirect_to :action => "cert" and return
    end

    # 画面表示確認用
#    redirect_to action:"disable_result", id:@cert.id and return

    # 証明書ステータスセット
    @cert.state = Cert::State::REVOKE_REQUESTED_FROM_USER
    @cert.save

    # リクエスト発行
    Rails.logger.debug "RaReq.request call: @cert = #{@cert.inspect}"
    RaReq.request(@cert)

    # 完了表示
    redirect_to action:"disable_result", id:@cert.id

  end

  # ----------------------------------------------------------------------
  # 失効申請完了画面
  def disable_result

    if !current_user
      return redirect_to :action => "index"
    end

    @cert = Cert.find_by_id(params[:id])

  end

  # ----------------------------------------------------------------------
  # 証明書削除操作
  def delete_post

    if !current_user
      return redirect_to :action => "index"
    end

    # 画面表示確認用
#    @cert = Cert.find_by_id(params[:id])
#    redirect_to action:"delete_result", id:@cert.user_id and return

    if params[:id].blank?
      flash[:alert] = "cert_id undefined."
      redirect_to :action => "cert" and return
    end

    # 証明書取得
    @cert = Cert.find_by_id(params[:id])
    if @cert.blank?
      flash[:alert] = "cert undefined."
      redirect_to :action => "cert" and return
    end

    # 画面表示確認用
#    redirect_to action:"delete_result", id:@cert.user_id and return

    # エラーファイル削除
    filename = "log/cert_" + params[:id] + "_error.html"
    if File.exist?(filename)
      File.delete filename
    end

    # DB削除
    @user_id = @cert.user_id
    Rails.logger.debug "Cert record delete: @cert = #{@cert.inspect}"
    @cert.destroy

    # 完了表示
    redirect_to action:"delete_result", id:@user_id

  end

  # ----------------------------------------------------------------------
  # 証明書削除結果
  def delete_result

    if !current_user
      return redirect_to :action => "index"
    end

    @user_id = params[:id]

  end

  # ----------------------------------------------------------------------
  # 管理者チェック
  def self.isAdmin(user)
    if user.blank? || user.uid.blank? 
      return false
    elsif SHIBCERT_CONFIG[Rails.env]['admin_uids'].include?(user.uid)
       return true
    elsif user.admin == true    # データベース設定フラグ(現在未使用)
      return false
#      return true
    end
    return false
  end

end
# ========================================================================
