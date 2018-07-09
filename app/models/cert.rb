# coding: utf-8
class Cert < ActiveRecord::Base
  belongs_to :cert_type
  belongs_to :cert_state
  belongs_to :user

  def self.update_expire_at(id:, serialnumber:, expire_at:, url_expire_at:)
    if id.present?
      logger.info("#{__method__}: serialnumber or expire_at is not set")
      return nil
    end
    cert = Cert.find(id)
    if cert.serialnumber.blank? && serialnumber.present?
      cert.serialnumber = serialnumber
    end
    if cert.expire_at.blank? && expire_at.present?
      cert.expire_at = expire_at
    end
    if cert.url_expire_at.blank? && url_expire_at.present?
      cert.url_expire_at = url_expire_at
    end
    cert.save
    logger.info("#{__method__}: updated expire_at for cert.id:#{cert.id}")
  end

  def self.update_from_mail(update_target:, value:, dn:)

    certs = Cert.where("dn = ?", dn).order(id: :desc)

    if certs.count == 0
      logger.info("#{__method__}: not found any record DN=#{dn}")
      return nil
    end

    case update_target

    when 'pin'
      expectState = Cert::State::NEW_REQUESTED_TO_NII
      cert = certs.find_by(state: expectState)
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and state=#{expectState}")
        return nil
      end
      cert.pin = value
      cert.state = Cert::State::NEW_GOT_PIN
      cert.save
      logger.info("#{__method__}: updated pin and state for DN:#{dn}")
      return true

    when 'x509_serialnumber'

      cert = nil
      certs.each do |c|
        cert = c if c.state == Cert::State::NEW_DISPLAYED_PIN || c.state == Cert::State::NEW_GOT_PIN
      end
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and state=NEW_DISPLAY_PIN|NEW_GOT_PIN")
        return nil
      end
      cert.serialnumber = value
      cert.state = Cert::State::NEW_GOT_SERIAL
      cert.save
      logger.info("#{__method__}: updated x509_serialnumber and state for DN:#{dn}")
      return true

    when 'revoked_x509_serialnumber'
      expectSerial = value
      cert = certs.find_by(serialnumber: expectSerial)
      if cert == nil
        logger.info("#{__method__}: not found any record DN=#{dn} and serialnumber=#{expectSerial}")
        return nil
      end
      cert.state = Cert::State::REVOKED
      cert.save
      logger.info("#{__method__}: REVOKED serialnumber=#{expectSerial}, DN:#{dn}")
      return true

    else
      logger.info("not supported type='#{update_target}'")
      return nil
    end
  end

  def x509_state
    s = state

    if State::REVOKE_REQUESTED_TO_NII <= s && s <= State::REVOKED
      return X509State::REVOKED
    end
    if s == State::NEW_ERROR || s == State::RENEW_ERROR || s == State::REVOKE_ERROR
      return X509State::ERROR
    end
    if expire_at != nil && expire_at <= Time.now
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

    return X509State::UNKNOWN
  end

  module PurposeType
    CLIENT_AUTH_CERTIFICATE = 5
    SMIME_CERTIFICATE = 7
  end
  
  module State
    # 新規発行
    NEW_REQUESTED_FROM_USER = 10 # 利用者から受付後、NIIへ申請前
    NEW_REQUESTED_TO_NII = 11   # 利用者から受付後、NIIへ申請直後
    NEW_RECEIVED_MAIL = 12 # 利用者から受付後、NIIへ申請後、メール受信済み
    NEW_GOT_PIN = 13 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み
    NEW_DISPLAYED_PIN = 14 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み、利用者へ受け渡し後
    NEW_GOT_SERIAL = 15    # 利用者が証明書を取得してシリアル番号を受信
    NEW_ERROR = 19

    # 更新
    RENEW_REQUESTED_FROM_USER = 20 # 利用者から受付後、NIIへ申請前
    RENEW_REQUESTED_TO_NII = 21   # 利用者から受付後、NIIへ申請直後
    RENEW_RECEIVED_MAIL = 22 # 利用者から受付後、NIIへ申請後、メール受信済み
    RENEW_GOT_PIN = 23 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み
    RENEW_DISPLAYED_PIN = 24 # 利用者から受付後、NIIへ申請後、メール受信済み、PIN受取済み、利用者へ受け渡し後
    RENEW_GOT_SERIAL = 25    # 利用者が証明書を取得してシリアル番号を受信
    RENEW_ERROR = 29

    # 失効
    REVOKE_REQUESTED_FROM_USER = 30 # 利用者から受付後、NIIへ申請前
    REVOKE_REQUESTED_TO_NII = 31   # 利用者から受付後、NIIへ申請直後
    REVOKE_RECEIVED_MAIL = 32 # 利用者から受付後、NIIへ申請後
    REVOKED = 33 # 利用者による失効済み
    REVOKE_ERROR = 39

    UNKNOWN = -1                # 不明
  end

  module X509State
    REQUESTING = 0
    VALID = 1
    EXPIRED = 2
    REVOKED = 3
    ERROR = 4
    UNKNOWN = 5
  end
end
