https://edenmal.moe/post/2018/GitLab-Keycloak-SAML-2-0-OmniAuth-Provider/

OAUTH_SAML_ASSERTION_CONSUMER_SERVICE_URL
OAUTH_SAML_IDP_CERT_FINGERPRINT
OAUTH_SAML_IDP_SSO_TARGET_URL
OAUTH_SAML_ISSUER
OAUTH_SAML_NAME_IDENTIFIER_FORMAT




gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_link_saml_user'] = true
gitlab_rails['omniauth_providers'] = [
  {
    name: 'saml',
    label: 'SAML',
    args: {




      attribute_statements: { username: ['username'] }
    }
  }
]

OAUTH_BLOCK_AUTO_CREATED_USERS=false
OAUTH_AUTO_SIGN_IN_WITH_PROVIDER=saml
OAUTH_ALLOW_SSO=saml
OAUTH_SAML_ASSERTION_CONSUMER_SERVICE_URL=https://gitlab.observe.global/users/auth/saml/callback
OAUTH_SAML_IDP_CERT_FINGERPRINT=41f1c588c928291c5dc30d11161d685231509ab8
OAUTH_SAML_IDP_SSO_TARGET_URL=https://keycloak.observe.global/auth/realms/observe/protocol/sam
OAUTH_SAML_ISSUER=https://gitlab.observe.global
OAUTH_SAML_NAME_IDENTIFIER_FORMAT=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent
DISBALED_OAUTH_SAML_ATTRIBUTE_STATEMENTS_EMAIL=mail
DISBALEDOAUTH_SAML_ATTRIBUTE_STATEMENTS_NAME=cnam
DISBALEDOAUTH_SAML_ATTRIBUTE_STATEMENTS_FIRST_NAME=cname
DISBALEDOAUTH_SAML_ATTRIBUTE_STATEMENTS_LAST_NAME=sn


```
{
  "clients": [
    {
      "clientId": "https://gitlab.observe.global",
      "rootUrl": "https://gitlab.observe.global",
      "enabled": true,
      "redirectUris": [
        "https://gitlab.observe.global/*"
      ],
      "protocol": "saml",
      "attributes": {
        "saml.assertion.signature": "false",
        "saml.force.post.binding": "true",
        "saml.multivalued.roles": "false",
        "saml.encrypt": "false",
        "saml.server.signature": "true",
        "saml.server.signature.keyinfo.ext": "false",
        "saml.signature.algorithm": "RSA_SHA256",
        "saml_force_name_id_format": "false",
        "saml.client.signature": "false",
        "saml.authnstatement": "true",
        "saml_name_id_format": "username",
        "saml.onetimeuse.condition": "false",
        "saml_signature_canonicalization_method": "http://www.w3.org/2001/10/xml-exc-c14n#"
      },
      "protocolMappers": [
        {
          "name": "email",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "email",
            "attribute.name": "email"
          }
        },
        {
          "name": "first_name",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "firstName",
            "attribute.name": "first_name"
          }
        },
        {
          "name": "last_name",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "lastName",
            "attribute.name": "last_name"
          }
        },
        {
          "name": "username",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "user.attribute": "username",
            "attribute.name": "username"
          }
        }
      ]
    }
  ]
}
```

-----BEGIN CERTIFICATE-----
MIICnTCCAYUCBgFmyRcGiTANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdvYnNlcnZlMB4XDTE4MTAzMTA3NDUyMVoXDTI4MTAzMTA3NDcwMVowEjEQMA4GA1UEAwwHb2JzZXJ2ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAI/quQQfWBuQgvxpkcqzkPmXmiO/XE9KmSLcoIOJuDMXXmev9WFtXYbKfozjrZgC4P0uPQLAXJU+2hO7U5fkaG2IuORCK/fKp+cD3GXVO38mxpGFdk3k2eTLUOFfVAUXpPT9dYPSs3EpiB/llslErBBG7bkfwHr06xjU2sMqo/pRbKDLvrqAaBMuHlgOHhAVWWxyzQuUF0kxHxsAbpOnzpiMMOZxhKKZiNEpozIOESplIKFsEYiS4w60z5ROmYEBVqMKP5rsEop9XgS+JNaqfjDbW/NOgT13bvxiA6HxEB0UGt2tWxVsnxpzp3v5rxnXzo1wZQO5KQYWNxJT9Wb9sy8CAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAIyrT5q/TC3CVF7YOAIrPCq+TEANnoaTUuq2BCG6ory+cnnI9T/qoW9c2GVYSrmdQraY8H3o4J+Trjz2OCmuk4Xdp326Lz7hGPuF6i2p9Dmbu696WDlwZHMm+Dn6lMegGb1WKJGAIB9JBss5lHqGbrAxUav9pWukKBZaNsFVnycOMGLQJuROf3jh/MNd7tcIhxAXQxWf//ZfYH7JfeK973L27oGyK+CrxGwsHIsuwSrkJVAPvWPADiPQFqExK/bC1DPGQO4YAV5rCJPTIwXL5I6l5Al2hw1FcAMND2bTA3MgYzg1aQvAJGO7+wQNQYOPkuhR1Hhb1JWGYj1YOdPnG+g==
-----END CERTIFICATE-----


https://edenmal.moe/post/2018/GitLab-Keycloak-SAML-2-0-OmniAuth-Provider/
