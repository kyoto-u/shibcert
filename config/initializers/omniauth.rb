Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, 'client-id', 'client-secret'

  if Rails.env.development?
    provider :identity, fields: [:uid,:name,:email], model: Identity
  end

  provider :saml,
           assertion_consumer_service_url:      "https://shibcert.iimc.kyoto-u.ac.jp/auth/saml/callback",
           issuer:                              "https://shibcert.iimc.kyoto-u.ac.jp/",
           idp_sso_target_url:                  "https://example.ac.jp/saml/saml2/idp/SSOService.php",
           idp_sso_target_url_runtime_params:   {original_request_param: :mapped_idp_param},
#           :idp_cert                            "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----",
           idp_cert_fingerprint:                "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx",

           name_identifier_format:              "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
           attribute_statements: {
             uid: [ 'uid' ],
             name: [ 'displayName' ],
             email: [ 'mail' ],
             kuMfaEnabled: [ 'kuMfaEnabled' ],
           },
           attribute_service_name:              "shibcert"
end
