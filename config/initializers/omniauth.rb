Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, 'client-id', 'client-secret'
  provider :saml,
           assertion_consumer_service_url:      "https://shibcert.iimc.kyoto-u.ac.jp/auth/saml/callback",
           issuer:                              "https://shibcert.iimc.kyoto-u.ac.jp/",
# auth (SAME)
           idp_sso_target_url:                  "https://example.ac.jp/saml/saml2/idp/SSOService.php",
           idp_sso_target_url_runtime_params:   {original_request_param: :mapped_idp_param},
#           :idp_cert                            "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----",
           idp_cert_fingerprint:                "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx",
           idp_cert_fingerprint_validator:      lambda { |fingerprint| fingerprint },
           name_identifier_format:              "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
           attribute_statements: {
             uid: [ 'urn:oid:0.9.2342.19200300.100.1.1' ],
             name: [ 'urn:oid:2.16.840.1.113730.3.1.241' ],
             email: [ 'urn:oid:0.9.2342.19200300.100.1.3' ],
           },
           attribute_service_name:              "shibcert"
end
