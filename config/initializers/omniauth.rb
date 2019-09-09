Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :shibboleth, { :debug => true }
  provider :shibboleth, {
	:uid_field => 'uid',
#	:uid_field => 'eppn',
	:name_field => 'displayName',
        :info_fields => {
          :email    => 'email',
#          :email    => 'mail',
          :location => 'contactAddress',
          :image    => 'photo_url',
          :phone    => 'contactPhone',
          :number   => 'gakuninScopedPersonalUniqueCode',
        },
#       :debug => true,
#	:request_type => :header,
  }

  provider :github, 'client-id', 'client-secret'
end
