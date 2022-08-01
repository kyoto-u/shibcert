class IpWhiteListValidator < ActiveModel::Validator
  def validate(record)
    if record.ip.blank?
      record.errors.add :base, "empty IP address"
    end
    begin
      IPAddr.new(record.ip)
    rescue IPAddr::InvalidAddressError
      record.errors.add :base, "invalid IP address"
    end
    if record.expired_at.blank?
      record.errors.add :base, "empty expired_at"
    end
  end
end

class IpWhiteList < ApplicationRecord
  validates :ip, uniqueness: true
  validates_with IpWhiteListValidator

  def valid_ip?
    begin
      IPAddr.new(self.ip)
    rescue IPAddr::InvalidAddressError
      return false
    end
    return true
  end

  private
  def self.include?(client_ip)
    self.all.pluck(:ip).each{|allow_ip|
      begin
        ip = IPAddr.new(allow_ip)
        return true if ip.include?(client_ip)
      rescue IPAddr::InvalidAddressError
        logger.debug("#{__method__}: skip invalid ip_white_list.ip: #{allow_ip}")
      end
    }
    return false
  end

end
