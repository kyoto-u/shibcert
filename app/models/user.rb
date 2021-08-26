class User < ActiveRecord::Base
  has_many :certs

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      info = auth['info']
      user.uid = info['uid']
      user.name = info['name'] || user.uid
      user.email = info['email']
    end
  end
end
