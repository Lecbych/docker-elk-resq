#!/usr/bin/env bash
set -eu
set -o pipefail

# Update the configuration file to enable OIDC
config_file="/usr/share/elasticsearch/config/elasticsearch.yml"

# Append OIDC configuration if not already present
if ! grep -q "xpack.security.authc.realms.oidc.${KEYCLOAK_CLIENT_NAME}:" "$config_file"; then
    cat <<EOL >> "$config_file"

xpack.security.authc.realms.oidc.${KEYCLOAK_CLIENT_NAME}:
  order: 2
  rp.client_id: "michal"
  rp.response_type: code
  rp.redirect_uri: "https://localhost:5601/api/security/oidc/callback"
  op.issuer: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}"
  op.authorization_endpoint: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}/protocol/openid-connect/auth"
  op.token_endpoint: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}/protocol/openid-connect/token"
  op.jwkset_path: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}/protocol/openid-connect/certs"
  op.userinfo_endpoint: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}/protocol/openid-connect/userinfo"
  op.endsession_endpoint: "${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_CLIENT_NAME}/protocol/openid-connect/logout"
  rp.post_logout_redirect_uri: "https://localhost:5601/logged_out"
  claims.principal: name
  ssl.verification_mode: none
EOL
fi
