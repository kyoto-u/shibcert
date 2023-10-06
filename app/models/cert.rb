# coding: utf-8
class Cert < ApplicationRecord
  belongs_to :user

  def set_attributes(params, user:)
    # purpose_type: profile ID of
    #   https://certs.nii.ac.jp/archive/TSV_File_Format/client_tsv/
    self.purpose_type = params[:cert]["purpose_type"].to_i
    self.user_id = user.id
    self.req_seq = user.cert_serial_max
    self.state = Cert::State::NEW_REQUESTED_FROM_USER
    self.download_type = 1
    self.pass_id = nil

    cn = "CN="
    if Cert.is_client_auth(self.purpose_type)
      if params[:cert]["pass_opt"].to_i == 1
        # UPKI-PASSクライアント証明書.
        cn += params[:cert]["pass_id"] + " " + user.name

        self.download_type = 2
        self.pass_id = params[:cert]["pass_id"]
      else
        cn += user.uid
        if params[:cert].has_key?("vlan_id") and !params[:cert]["vlan_id"].empty?
          # VLANのクライアント証明書.
          self.vlan_id = params[:cert]["vlan_id"].strip
          cn += "@" + self.vlan_id
        end
      end
      self.dn = cn + ".#{self.req_seq}"
    elsif Cert.is_smime(self.purpose_type)
      self.dn = cn + user.email + ",OU=No #{self.req_seq}"
    end

    if Rails.env != 'production' then
      self.dn += '.' + SHIBCERT_CONFIG[Rails.env]['base_dn_dev']
    end
    self.dn += ','

    if Cert.is_client_auth(self.purpose_type)
      self.dn += SHIBCERT_CONFIG[Rails.env]['base_dn_auth']
    elsif Cert.is_smime(self.purpose_type)
      self.dn += SHIBCERT_CONFIG[Rails.env]['base_dn_smime']
    end
  end


  def self.update_by_tsv(id:, serialnumber:, state:, expires_at:, url_expires_at:)
    updated = []
    if !id
      logger.info("#{__method__}: serialnumber or expires_at is not set")
      return nil
    end
    cert = Cert.find(id)
    if cert.serialnumber.blank? && serialnumber.present?
      cert.serialnumber = serialnumber
      updated << "serialnumber"
    end
    if state && cert.state != state
      cert.state = state
      updated << "state"
    end
    if cert.expires_at.blank? && expires_at.present?
      cert.expires_at = expires_at
      updated << "expires_at"
    end
    if cert.url_expires_at.blank? && url_expires_at.present?
      cert.url_expires_at = url_expires_at
      updated << "url_expires_at"
    end
    if not updated.empty?
      cert.save
      logger.info("#{__method__}: updated for cert.id:#{cert.id} update:#{updated.join(',')}")
    end
  end

  def self.update_from_login(userid)
#    logger.debug("#{__method__}: check update from login id = #{userid}")
    certs = Cert.where(user_id: userid).order("created_at DESC")
    if certs.count == 0
      return
    end
    chkdate = Date.today.prev_day(28)
#    logger.debug("#{__method__}: check date = #{chkdate}")
    certs.each do |cert|
#      logger.debug("#{__method__}: cert = #{cert.id} / created_at = #{cert.created_at} / state = #{cert.state}")
      if cert.state == Cert::State::NEW_GOT_PIN && cert.created_at < chkdate
        logger.info("#{__method__}: time out new cert id = #{cert.id}")
        cert.state = Cert::State::NEW_GOT_TIMEOUT
        cert.save
      end
      if cert.state == Cert::State::RENEW_GOT_PIN && cert.created_at < chkdate
        logger.info("#{__method__}: time out renew cert id = #{cert.id}")
        cert.state = Cert::State::RENEW_GOT_TIMEOUT
        cert.save
      end
    end

  end

  def self.update_from_mail(update_target:, value:, dn:, name:, serial:)

p dn

    # DNで証明書群取得
    certs = Cert.where("dn = ?", dn).order(id: :desc)
    if certs.count == 0
      logger.info("#{__method__}: not found any record DN=#{dn}")
      return nil
    end

    # ケース毎処理
    case update_target

    when 'pin'
      # P12個別:PIN更新
      expectState = Cert::State::NEW_REQUESTED_TO_NII
      cert = certs.find_by(state: expectState)
      if cert == nil
        expectState = Cert::State::RENEW_REQUESTED_TO_NII
        cert = certs.find_by(state: expectState)
        if cert == nil
          logger.info("#{__method__}: not found any record DN=#{dn} and state=#{expectState}")
          return nil
        end
      end
      cert.pin = value
      if expectState == Cert::State::NEW_REQUESTED_TO_NII
        cert.state = Cert::State::NEW_GOT_PIN
      else
        cert.state = Cert::State::RENEW_GOT_PIN
      end
      cert.pin_get_at = Time.now
      cert.save
      logger.info("#{__method__}: updated pin and state for DN:#{dn}")
      return true

    when 'x509_serialnumber'
      # P12個別:シリアル番号更新
      cert = nil
      state = -1
      certs.each do |c|
        if c.state == Cert::State::NEW_DISPLAYED_PIN || c.state == Cert::State::NEW_GOT_PIN
          cert = c
          state = Cert::State::NEW_GOT_SERIAL
        end
        if c.state == Cert::State::RENEW_DISPLAYED_PIN || c.state == Cert::State::RENEW_GOT_PIN
          cert = c
          state = Cert::State::RENEW_GOT_SERIAL
        end
      end
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and state=NEW_DISPLAY_PIN|NEW_GOT_PIN")
        return nil
      end
      cert.serialnumber = serial
      cert.state = state
      cert.get_at = Time.now
      cert.save
      logger.info("#{__method__}: updated x509_serialnumber and state for DN:#{dn}")
      if !cert.pass_id.blank?
        logger.info("#{__method__}: UPKI-PASS serial update is not needed DN=#{dn}")
        return nil
      end
      return true

    when 'revoked_x509_serialnumber'
      # 失効更新
      expectSerial = value
      cert = certs.find_by(serialnumber: expectSerial)
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and serialnumber=#{expectSerial}")
        return nil
      end
      if !cert.pass_id.blank?
        # UPKI-PASSサーバへ失効通知
        rep = RaReq.upkiPassRevoke(cert)
        if rep == nil
          logger.info("#{__method__}: Upki-pass revoke error DN=#{cert.dn}")
          return nil
        elsif rep.start_with?("err:")
          logger.info("#{__method__}: Upki-pass revoke error '" + rep + "' DN=#{cert.dn}")
          return nil
        end
        logger.info("#{__method__}: UPKI-PASS server revoke updated serial=#{expectSerial}")
      end
      cert.state = Cert::State::REVOKED
      cert.save
      logger.info("#{__method__}: REVOKED serialnumber=#{expectSerial}, DN:#{dn}")
      return true

    when 'upasspin'
      # P12一括:UPKI-PASS PIN更新
      expectState = Cert::State::NEW_PASS_REQUESTED
      cert = certs.find_by(state: expectState)
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and state=#{expectState}")
        return nil
      end
      # PIN更新
      cert.pass_pin = value
#      cert.pass_id = name.split[0]
      cert.pin_get_at = Time.now
      cert.save
      id = cert.id
      logger.info("#{__method__}: updated pass pin and state for DN:#{dn}")
      return true

    when 'upassfile'
      # P12一括:UPKI-PASS P12ファイル更新(先にupasspin実行が必須)
      expectState = Cert::State::NEW_PASS_REQUESTED
      cert = certs.find_by(state: expectState)
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and state=#{expectState}")
        return nil
      end
      # P12ファイルとシリアル番号の更新
      cert.pass_p12 = value
      cert.serialnumber = serial
#      cert.pass_id = name.split[0]
      cert.get_at = Time.now
      cert.save
      logger.info("#{__method__}: updated pass pin and state for DN:#{dn}")
      # UPKI-PASSサーバ連携
      if cert.pass_pin.blank?
        logger.info("#{__method__}: Upki-pass pin not find DN=#{dn}")
        return nil
      end
      # PIN登録済みなのでサーバ連携
      rep = RaReq.upkiPassCert(cert)
      if rep == nil
        logger.info("#{__method__}: Upki-pass update error DN=#{dn}")
        return nil
      elsif rep.start_with?("err:")
        logger.info("#{__method__}: Upki-pass update error '" + rep + "' DN=#{dn}")
        return nil
      end
      logger.info("#{__method__}: UPKI-PASS server updated DN=#{dn} and state=#{expectState}")
      # 成功したので情報をクリアしてステータス更新
      cert.pass_pin = nil
      cert.pass_p12 = nil
      cert.state = Cert::State::NEW_PASS_GOT_CERT
      cert.save
      return true

    else
      logger.info("not supported type='#{update_target}'")
      return nil
    end
  end

  def next_state
    if [nil,
        State::NEW_ERROR,
        State::RENEW_ERROR,
        State::REVOKE_ERROR,
        State::UNKNOWN].include?(self.state)
      raise RuntimeError, "invalid Cert.state #{self.state}"
    end
    if [State::NEW_GOT_SERIAL,
        State::RENEW_GOT_SERIAL,
        State::REVOKED].include?(self.state)
      raise RuntimeError, "no next state #{self.state}"
    end
    self.state += 1
  end

  def set_error_state
    if State::NEW_REQUESTED_FROM_USER <= self.state &&
       self.state <= State::NEW_ERROR
      self.state = State::NEW_ERROR
    elsif State::RENEW_REQUESTED_FROM_USER <= self.state &&
       self.state <= State::RENEW_ERROR
      self.state = State::RENEW_ERROR
    elsif State::REVOKE_REQUESTED_FROM_USER <= self.state &&
       self.state <= State::REVOKE_ERROR
      self.state = State::REVOKE_ERROR
    else
      raise RuntimeError, "unknown current state"
    end
  end

  def x509_state
    s = state

    if s == State::NEW_GOT_TIMEOUT || s == State::RENEW_GOT_TIMEOUT
      return X509State::TIMEOUT
    end
    if State::REVOKE_REQUESTED_TO_NII <= s && s <= State::REVOKED
      return X509State::REVOKED
    end
    if s == State::NEW_ERROR || s == State::RENEW_ERROR || s == State::REVOKE_ERROR
      return X509State::ERROR
    end
    if expires_at != nil && expires_at <= Time.now
      return X509State::EXPIRED
    end

    if State::NEW_GOT_PIN    <= s && s <= State::NEW_GOT_SERIAL ||
       State::RENEW_GOT_PIN  <= s && s <= State::RENEW_GOT_SERIAL ||
       state == State::REVOKE_REQUESTED_FROM_USER # exceptional
      return X509State::VALID
    end

    if State::NEW_REQUESTED_FROM_USER    <= s && s <= State::NEW_RECEIVED_MAIL ||
       State::RENEW_REQUESTED_FROM_USER  <= s && s <= State::RENEW_RECEIVED_MAIL
      return X509State::REQUESTING
    end

    if State::NEW_PASS_REQUESTED
      return X509State::UPKIPASS
    end

    return X509State::UNKNOWN
  end

  def self.is_smime(purpose_type)
    [Cert::PurposeType::SMIME_CERTIFICATE_52,
     Cert::PurposeType::SMIME_CERTIFICATE_13,
     Cert::PurposeType::SMIME_CERTIFICATE_25].include?(purpose_type.to_i)
  end

  def self.is_client_auth(purpose_type)
    [Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_52,
     Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_13,
     Cert::PurposeType::CLIENT_AUTH_CERTIFICATE_25].include?(purpose_type.to_i)
  end

  module PurposeType
    CLIENT_AUTH_CERTIFICATE = 5 	# 5: 52 months, 13: 13 months, 14: 25 months
    SMIME_CERTIFICATE = 7		# 7: 52 months, 15: 13 months, 16: 25 months
    CLIENT_AUTH_CERTIFICATE_52 = 5
    SMIME_CERTIFICATE_52 = 7
    CLIENT_AUTH_CERTIFICATE_13 = 13
    SMIME_CERTIFICATE_13 = 15
    CLIENT_AUTH_CERTIFICATE_25 = 14
    SMIME_CERTIFICATE_25 = 16
  end

  module State
    # 新規発行
    NEW_REQUESTED_FROM_USER = 10 # 利用者から受付後、NIIへ申請前
    NEW_REQUESTED_TO_NII = 11   # 利用者から受付後、NIIへ申請直後
    NEW_RECEIVED_MAIL = 12 # 利用者から受付後、NIIへ申請後、メール受信済み
    NEW_GOT_PIN = 13 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み
    NEW_DISPLAYED_PIN = 14 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み、利用者へ受け渡し後
    NEW_GOT_SERIAL = 15    # 利用者が証明書を取得してシリアル番号を受信
    NEW_GOT_TIMEOUT = 16    # PIN受取済みだが証明書を取得しなかった(1ヶ月経過した)
    NEW_PASS_REQUESTED = 17   # 利用者からUPKI-PASS受付後、NIIへ申請直後
    NEW_PASS_GOT_CERT = 18   # UPKI-PASS、NIIへ申請後、メール受信済み、PIN/CERT受取済み、UPKI-PASSサーバ依頼済み
    NEW_ERROR = 19

    # 更新
    RENEW_REQUESTED_FROM_USER = 20 # 利用者から受付後、NIIへ申請前
    RENEW_REQUESTED_TO_NII = 21   # 利用者から受付後、NIIへ申請直後
    RENEW_RECEIVED_MAIL = 22 # 利用者から受付後、NIIへ申請後、メール受信済み
    RENEW_GOT_PIN = 23 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み
    RENEW_DISPLAYED_PIN = 24 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み、利用者へ受け渡し後
    RENEW_GOT_SERIAL = 25    # 利用者が証明書を取得してシリアル番号を受信
    RENEW_GOT_TIMEOUT = 26    # PIN受取済みだが証明書を取得しなかった(1ヶ月経過した)
    RENEW_ERROR = 29

    # 失効
    REVOKE_REQUESTED_FROM_USER = 30 # 利用者から受付後、NIIへ申請前
    REVOKE_REQUESTED_TO_NII = 31   # 利用者から受付後、NIIへ申請直後
    REVOKE_RECEIVED_MAIL = 32 # 利用者から受付後、NIIへ申請後
    REVOKED = 33 # 利用者による失効済み
    REVOKE_ERROR = 39

    # 非表示
    UNKNOWN = -1                # 不明(未表示)
  end

  module X509State
    REQUESTING = 0
    VALID = 1
    EXPIRED = 2
    REVOKED = 3
    ERROR = 4
    UNKNOWN = 5
    UPKIPASS = 6
    TIMEOUT = 7
  end
end
