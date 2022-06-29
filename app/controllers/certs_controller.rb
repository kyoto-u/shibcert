# coding: utf-8

# ========================================================================
# CertsController: 証明書発行操作クラス.
class CertsController < ApplicationController
  before_action :check_user, only: [:index, :request_post, :disable_result, :renew_post]
  before_action :set_cert_of_user, only: [:show, :edit_memo_remote, :request_result, :disable_post, :disable_result, :renew_post, :renew_result]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # ----------------------------------------------------------------------
  def record_not_found
    render file: Rails.root.join('public/404.html'), status: 404, layout: false, content_type: 'text/html'
  end

  def working_smime_num(myid)
    # FIXME: generating terrible SQL

    smime_num = 0

    certs = Cert.where(user_id: myid).merge(Cert.where(purpose_type: Cert::PurposeType::SMIME_CERTIFICATE_52)
                                              .or(Cert.where(purpose_type: Cert::PurposeType::SMIME_CERTIFICATE_13))
                                              .or(Cert.where(purpose_type: Cert::PurposeType::SMIME_CERTIFICATE_25)))

    month_to_live = Array.new
    month_to_live[Cert::PurposeType::SMIME_CERTIFICATE_52] = 52
    month_to_live[Cert::PurposeType::SMIME_CERTIFICATE_13] = 13
    month_to_live[Cert::PurposeType::SMIME_CERTIFICATE_25] = 25

    now = DateTime.now

    certs.each do |cert|

      if [Cert::State::NEW_GOT_SERIAL,
        Cert::State::NEW_REQUESTED_TO_NII,
        Cert::State::NEW_RECEIVED_MAIL,
        Cert::State::NEW_GOT_PIN,
        Cert::State::NEW_DISPLAYED_PIN,
        Cert::State::NEW_GOT_SERIAL,
        Cert::State::RENEW_REQUESTED_FROM_USER,
        Cert::State::RENEW_REQUESTED_TO_NII,
        Cert::State::RENEW_RECEIVED_MAIL,
        Cert::State::RENEW_GOT_PIN,
        Cert::State::RENEW_DISPLAYED_PIN,
        Cert::State::RENEW_GOT_SERIAL,
       ].include?(cert[:state])

        if cert[:expire_at].nil?
          expire_at = cert[:created_at].since(month_to_live[cert[:purpose_type]].month)
          if now < expire_at
            smime_num += 1
          end
        else
          if now < cert[:expire_at]
            smime_num += 1
          end
        end
      end
    end
    return smime_num
  end

  # GET /certs
  # GET /certs.json
  def index
    # オプション設定.
    @pass_opt = false
    # S/MIME数
    @smime_num = working_smime_num(current_user.id)
    # 表示設定.
    if params[:opt] == nil || params[:opt][:all] == nil || request.get?
      # 指定無し(オプション未指定かGETメソッド)
      if cookies[:opt_all] == nil
        @all_certs_opt = 1				# デフォルト値.
      else
        @all_certs_opt = cookies[:opt_all].to_i	# クッキーから.
      end
    else
      @all_certs_opt = params[:opt][:all].to_i	# オプション指定.
    end
    # 証明書取得.
    @certs = Cert.where(user_id: current_user.id).order("created_at DESC")
    if @all_certs_opt == 0 && !@certs.blank?
      # 有効な証明書のみ抽出.
      now = Time.now
      @certs = @certs.select { |s| \
                                 (!s.expire_at || s.expire_at > now) && \
                               s.state != Cert::State::NEW_GOT_TIMEOUT && \
                               s.state != Cert::State::NEW_ERROR && \
                               s.state != Cert::State::RENEW_GOT_TIMEOUT && \
                               s.state != Cert::State::RENEW_ERROR && \
                               s.state != Cert::State::REVOKED && \
                               s.state != Cert::State::REVOKE_ERROR && \
                               s.state != Cert::State::UNKNOWN }
    end
    # 設定のクッキーへの保存.
    cookies[:opt_all] = { :value => @all_certs_opt, :expires => 7.days.from_now }
  end

  # GET /certs/1
  # GET /certs/1.json
  def show
    @user = User.find(@cert.user_id)
    unless /\d+/.match(params[:id])
      return
    end
  end

  # GET /certs/request_select
  # [memo] "request" is reserved by rails system
  def request_select
  end

  # POST /certs/request_post [with RPG pattern]
  def request_post
    if !request_post_params_is_valid
      return redirect_to :action => "index"
    end

    current_user.cert_serial_max += 1
    if !current_user.save
      flash[:alert] = t('.max_err')
      return redirect_to :action => "index"
    end

    @cert = Cert.new
    @cert.set_attributes(params, user: current_user)
    if(!@cert.save)
      flash[:alert] = t('.save_err')
      return redirect_to :action => "index"
    end
    tsv = RaReq.generate_tsv_new(@cert)
    Rails.logger.debug "#{__method__}: call RaReq.request with tsv:#{tsv.inspect}"
    if RaReq.request(RaReq::ApplyType::New, tsv) == true
      if @cert.download_type == 1
        @cert.next_state
      else
        @cert.state = Cert::State::NEW_PASS_REQUESTED
      end
    else
      @cert.set_error_state
      flash[:alert] = 'Your request fails. Please see https://certs.nii.ac.jp/news'
    end
    @cert.save
    redirect_to request_result_path(@cert.id)
  end

  # GET /certs/request_result [with RPG pattern]
  def request_result
    if current_user and current_user.email
      @maddr = current_user.email
    else
      @maddr = 'error: invalid email address'
    end
  end

  # POST /certs/disable_post [with RPG pattern]
  def disable_post
    @cert.state = Cert::State::REVOKE_REQUESTED_FROM_USER
    @cert.save

    tsv = RaReq.generate_tsv_revoke(@cert)

    Rails.logger.debug "RaReq.request call: @cert = #{@cert.inspect}"
    if RaReq.request(RaReq::ApplyType::Revoke, tsv) == true
      @cert.next_state
      flash[:notice] = "revoke success"
    else
      @cert.set_error_state
      flash[:alert] = "revoke error"
    end
    @cert.save

    redirect_to disable_result_path(@cert.id)
  end

  # POST /certs/disable_result [with RPG pattern]
  def disable_result
  end

  # POST /certs/renew_post [with RPG pattern]
  def renew_post
#      flash[:alert] = "renew error"
#      return redirect_to :action => "index"

    if @cert
      @newcert = Cert.new
      @newcert.user_id = current_user.id
      @newcert.purpose_type = @cert.purpose_type
      @newcert.download_type = @cert.download_type
      @newcert.vlan_id = @cert.vlan_id
      @newcert.pass_id = @cert.pass_id
      @newcert.dn = @cert.dn
      @newcert.serialnumber = @cert.serialnumber
#      @newcert.serialnumber = nil
      @newcert.state = Cert::State::RENEW_REQUESTED_FROM_USER

      ActiveRecord::Base.transaction do
        current_user.cert_serial_max += 1
        current_user.save # TODO: need error check
      end

      @newcert.req_seq = current_user.cert_serial_max
      @newcert.save

      Rails.logger.debug "RaReq.request call: @newcert = #{@newcert.inspect}"
      RaReq.request(@newcert)
    end

    redirect_to renew_result_path(@newcert.id)
  end

  # POST /certs/renew_result [with RPG pattern]
  def renew_result
  end

  # POST /certs/1/edit_memo_remote
  def edit_memo_remote
#    @cert.update('memo = ' + params[:memo])
#    @cert.update_attributes = {memo: params[:memo]}
    if @cert
      @cert.attributes = params.require(:cert).permit(:memo)
      @cert.save
    end
    redirect_to cert_show_path(@cert.id), notice: "Memo was updated"
  end

  # POST /certs
  # POST /certs.json
  def create
    @cert = Cert.new(cert_params)

    respond_to do |format|
      if @cert.save
        format.html { redirect_to @cert, notice: 'Cert was successfully created.' }
        format.json { render action: 'show', status: :created, location: @cert }
      else
        format.html { render action: 'new' }
        format.json { render json: @cert.errors, status: :unprocessable_entity }
      end
    end
  end

  def request_post_params_is_valid
    purpose_type = params[:cert]["purpose_type"].to_i

    if !Cert.is_smime(purpose_type) && !Cert.is_client_auth(purpose_type)
      # something wrong. TODO: need error handling
      flash[:alert] = t('.unknowen_purpose_type_err')
      Rails.logger.info "#{__method__}: unknown purpose_type #{params[:cert]['purpose_type']}"
      return false
    end

    if Cert.is_smime(purpose_type)
      working_smime_num(current_user.id) > 0
      flash[:alert] = t('.mime_err')
      return false
    end

    # Client Cert
    if Cert.is_client_auth(purpose_type)
      if params[:cert]["pass_opt"].to_i == 1
        # UPKI-PASSクライアント証明書.
        if params[:cert]["pass_id"].blank?
          flash[:alert] = t('.pass_err')
          return false
        end
      else
        unless params[:cert]["vlan_id"].blank?
          # VLANのクライアント証明書.
          vlan_id = params[:cert]["vlan_id"].strip
          if vlan_id.to_i == 0  # to_i return 0 if vlan_id is not Integer
            flash[:alert] = t('.vlan_err')
            return false
          end
        end
      end
    end
    return true
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cert
    @cert = Cert.find(params[:id])
  end

  def do_not_use
    @cert = nil
    return false
  end

  def check_user
    if !current_user
      redirect_to :action => "index"
    end
  end

  def set_cert_of_user
    if !current_user
      redirect_to :action => "index"
      return
    end
    mycert = Cert.find(params[:id])

    if mycert and mycert.user_id == current_user.id
      @cert = mycert
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cert_params
    params.require(:cert).permit(:vlan_id, :memo, :get_at, :expire_at, :pin, :pin_get_at, :user_id, :purpose_type, pass_id)
  end
end
