# coding: utf-8

# ========================================================================
# CertsController: 証明書発行操作クラス.
class CertsController < ApplicationController
  before_action :set_cert, only: [:edit, :update, :destroy]
  before_action :set_cert_of_user, only: [:show, :edit_memo_remote, :request_result, :disable_post, :disable_result, :renew_post, :renew_result]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # ----------------------------------------------------------------------
  def record_not_found
    render file: Rails.root.join('public/404.html'), status: 404, layout: false, content_type: 'text/html'  
  end

  def working_smime_num(myid)
    # FIXME: generating terrible SQL    
    smime_num = Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_GOT_SERIAL).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_REQUESTED_TO_NII).count() 
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_RECEIVED_MAIL).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_GOT_PIN).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_DISPLAYED_PIN).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::NEW_GOT_SERIAL).count() 
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_REQUESTED_FROM_USER).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_REQUESTED_TO_NII).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_RECEIVED_MAIL).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_GOT_PIN).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_DISPLAYED_PIN).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::RENEW_GOT_SERIAL).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::REVOKE_REQUESTED_FROM_USER).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::REVOKE_REQUESTED_TO_NII).count()
    smime_num += Cert.where(user_id: myid, purpose_type: 7, state: Cert::State::REVOKE_RECEIVED_MAIL).count()
    return smime_num
  end
  
  # GET /certs
  # GET /certs.json
  def index
    if current_user
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
  end

  # GET /certs/1
  # GET /certs/1.json
  def show

    if !current_user
      return redirect_to :action => "index"
    end

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
    # purpose_type: profile ID of
    #   https://certs.nii.ac.jp/archive/TSV_File_Format/client_tsv/

    if !current_user
      return redirect_to :action => "index"
    end

    download_type = 1
    pass_id = nil

    # S/MIME-multiple-application guard (failsafe)    
    if params[:cert]["purpose_type"].to_i == Cert::PurposeType::SMIME_CERTIFICATE and working_smime_num(current_user.id) > 0
       flash[:alert] = t('.mime_err')
       return redirect_to :action => "index"
    end

    # Client Cert
    if params[:cert]["purpose_type"].to_i == Cert::PurposeType::CLIENT_AUTH_CERTIFICATE
      if params[:cert]["pass_opt"].to_i == 1
        # UPKI-PASSクライアント証明書.
        if params[:cert]["pass_id"].blank?
#          @errmesg = t('.pass_err')
#          return
          flash[:alert] = t('.pass_err')
          return redirect_to :action => "index"
        end
        download_type = 2
        pass_id = params[:cert]["pass_id"]
        cn = "CN=" + params[:cert]["pass_id"] + " " + "#{current_user.name}"
      else
        if params[:cert]["vlan"] == "true"
          # VLANのクライアント証明書.
          vlan_id = params[:cert]["vlan_id"].strip
          vlan_id_i = vlan_id.to_i || 0
          if vlan_id_i == 0
#            flash[:alert] = "VLAN ID is invalid."
            flash[:alert] = t('.vlan_err')
            return redirect_to :action => "index"
          else
            cn = "CN=#{current_user.uid}" + "@" + vlan_id
          end
        else
          # 普通のクライアント証明書.
          cn = "CN=#{current_user.name}"
        end
      end
    end

    ActiveRecord::Base.transaction do      
      current_user.cert_serial_max += 1
      if(!current_user.save)
        flash[:alert] = t('.max_err')
        return redirect_to :action => "index"
      end
    end        
    
    case params[:cert]["purpose_type"].to_i

    when Cert::PurposeType::CLIENT_AUTH_CERTIFICATE
      if Rails.env == 'development' then
        dn = cn + ",OU=No #{current_user.cert_serial_max.to_s}" + "," + SHIBCERT_CONFIG[Rails.env]['base_dn_dev'] + "," + SHIBCERT_CONFIG[Rails.env]['base_dn_auth']
      else
        dn = cn + ",OU=No #{current_user.cert_serial_max.to_s}," + SHIBCERT_CONFIG[Rails.env]['base_dn_auth']
      end

    when Cert::PurposeType::SMIME_CERTIFICATE
      if Rails.env == 'development' then
        dn = "CN=#{current_user.email},OU=No #{current_user.cert_serial_max.to_s}," + SHIBCERT_CONFIG[Rails.env]['base_dn_dev'] + "," + SHIBCERT_CONFIG[Rails.env]['base_dn_smime']
      else
        dn = "CN=#{current_user.email},OU=No #{current_user.cert_serial_max.to_s}," + SHIBCERT_CONFIG[Rails.env]['base_dn_smime']
      end

    else
      # something wrong. TODO: need error handling
      Rails.logger.info "#{__method__}: unknown purpose_type #{params[:cert]['purpose_type']}"
      dn = ""
      return
    end
    
    request_params = params.require(:cert).permit(:purpose_type).merge(
      {user_id: current_user.id,
       state: Cert::State::NEW_REQUESTED_FROM_USER,
       dn: dn,
       download_type: download_type,
       vlan_id: vlan_id,
       pass_id: pass_id,
       req_seq: current_user.cert_serial_max})
    @cert = Cert.new(request_params)
    if(!@cert.save)
      flash[:alert] = t('.save_err')
      return redirect_to :action => "index"
    end

    Rails.logger.debug "RaReq.request call: @cert = #{@cert.inspect}"
    RaReq.request(@cert)
 
    redirect_to request_result_path(@cert.id)
  end

  # GET /certs/request_result [with RPG pattern]
  def request_result

    if !current_user
      return redirect_to :action => "index"
    end

    if current_user and current_user.email
      @maddr = current_user.email
    else
      @maddr = 'error: invalid email address'
    end
  end

  # POST /certs/disable_post [with RPG pattern]  
  def disable_post

    if !current_user
      return redirect_to :action => "index"
    end

#      flash[:alert] = "revoke error"
#      return redirect_to :action => "show"

    if @cert
      @cert.state = Cert::State::REVOKE_REQUESTED_FROM_USER
      @cert.save
      
      Rails.logger.debug "RaReq.request call: @cert = #{@cert.inspect}"    
      RaReq.request(@cert)
    end

    redirect_to disable_result_path(@cert.id)    
  end

  # POST /certs/disable_result [with RPG pattern]
  def disable_result

    if !current_user
      return redirect_to :action => "index"
    end
    
  end

  # POST /certs/renew_post [with RPG pattern]  
  def renew_post

    if !current_user
      return redirect_to :action => "index"
    end

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

    if !current_user
      return redirect_to :action => "index"
    end
    
  end

  # GET /certs/new
  def new
    @cert = Cert.new
  end

  # GET /certs/1/edit
  def edit
  end

  # POST /certs/1/edit_memo_remote
  def edit_memo_remote
#    @cert.update('memo = ' + params[:memo])
#    @cert.update_attributes = {memo: params[:memo]}
    if @cert
      @cert.attributes = params.require(:cert).permit(:memo)
      @cert.save
    end
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

  # PATCH/PUT /certs/1
  # PATCH/PUT /certs/1.json
  def update
    respond_to do |format|
      if @cert.update(cert_params)
        format.html { redirect_to @cert, notice: 'Cert was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @cert.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /certs/1
  # DELETE /certs/1.json
  def destroy
    @cert.destroy
    respond_to do |format|
      format.html { redirect_to certs_url }
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cert
    @cert = Cert.find(params[:id])    
  end

  def set_cert_of_user
#    FIXME: fix for not found error
#    begin
#      mycert = Cert.find(params[:id])
#    rescue ActiveRecord::RecordNotFound => e
#      mycert = nil
#    end

    if !current_user
      return redirect_to :action => "index"
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
      params.require(:cert).permit(:vlan_id, :memo, :get_at, :expire_at, :pin, :pin_get_at, :user_id, :cert_state_id, :cert_type_id, :purpose_type, pass_id)
    end
end
