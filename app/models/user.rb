class User < ActiveRecord::Base
  has_many :certs

  def self.create_with_omniauth(auth)
    create! do |user|
      info = auth[:info]
      user.provider = auth[:provider]
      user.uid = case user.provider
                 when 'identity'
                   Identity.find(auth[:uid])[:uid]
                 when 'saml'
                   info[:uid]
                 else
                   auth[:uid]
                 end
      user.name = info[:name] || user.uid
      user.email = info[:email]
    end
  end
end
