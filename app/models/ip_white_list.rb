class IpWhiteListValidator < ActiveModel::Validator
  def validate(record)
    if record.ip.blank?
      record.errors.add :base, "empty IP address"
    end
    begin
      IPAddr.new(record.ip)
    rescue
      record.errors.add :base, "invalid IP address"
    end
    if record.expired_at.blank?
      record.errors.add :base, "empty expired_at"
    end
  end
end

class IpWhiteList < ApplicationRecord
  validates_with IpWhiteListValidator

  def valid_ip?
    begin
      IPAddr.new(self.ip)
    rescue IPAddr::InvalidAddressError
      return false
    end
    return true
  end

end
