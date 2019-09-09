require 'date'

class CertCounter
  def self.execute
    certs = Cert.where('state = ? or state = ?', Cert::State::NEW_GOT_SERIAL, Cert::State::RENEW_GOT_SERIAL)
    client_certs = certs.where(purpose_type: Cert::PurposeType::CLIENT_AUTH_CERTIFICATE)
    smime_certs =  certs.where(purpose_type: Cert::PurposeType::SMIME_CERTIFICATE)

    today = Date.today
    day = Date.new(2018,1,1)
 
    while day <= today
      day2 = day >> 1
      cc = client_certs.where(created_at: [day...day2]).count
      sc =  smime_certs.where(created_at: [day ..day2]).count
#      printf("%s\t%s\t%d\t%d\n", day.strftime('%Y-%m-%d'), day2.strftime('%Y-%m-%d'), cc, sc)
      printf("%s\t%d\t%d\n", day.strftime('%Y-%m'), cc, sc)
      day = day2
    end
  end
end

CertCounter.execute
