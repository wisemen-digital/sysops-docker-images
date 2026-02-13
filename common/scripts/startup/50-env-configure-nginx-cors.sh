#!/usr/bin/env sh

set -eu

# Configure nginx CORS rules based on ENV vars
#
# Inputs:
# - NGINX_CORS_ORIGINS: defaults to '*'
# - NGINX_CORS_RESOURCE_POLICY: defaults to 'same-origin'

# Set defaults & clean up (normalize, trim, …)
readonly NGINX_CONFIG_FILE=/etc/nginx/snippets/vars/cors-origin.conf
readonly NGINX_CORS_ORIGINS=$(echo "${NGINX_CORS_ORIGINS:-*}" \
  | sed 's/,/ /g; s/^ *//; s/ *$//; s/  */ /g')
readonly NGINX_CORS_RESOURCE_POLICY="${NGINX_CORS_RESOURCE_POLICY:-same-origin}"

# Check nginx structure
if [ ! -f "${NGINX_CONFIG_FILE}" ]; then
  exit 0
fi

# Variables used for `Access-Control-Allow-Origin` (and credentials)
if [ "$NGINX_CORS_ORIGINS" = "*" ]; then
  echo "Nginx: configuring CORS origin with wildcard (allow all)…"
  cat <<EOF > "${NGINX_CONFIG_FILE}"
# Allow all origins
map "" \$cors_origin {
  default "*";
}
EOF
else
  echo "Nginx: configuring CORS origin with '${NGINX_CORS_ORIGINS}'…"
  cat <<EOF > "${NGINX_CONFIG_FILE}"
# Allow specified origins
map "\$http_origin" \$cors_origin {
  default "";
EOF
  for item in $NGINX_CORS_ORIGINS; do
    echo "  \"~^https?://$item(:\d+)?\$\" \"\$http_origin\";" >> "${NGINX_CONFIG_FILE}"
  done
  echo '}' >> "${NGINX_CONFIG_FILE}"
fi

cat <<EOF >> "${NGINX_CONFIG_FILE}"
# Only allow credentials if cors is not empty and not '*'
map "\$cors_origin" \$cors_allow_credentials {
  ""      "";
  "*"     "";
  default "true";
}
# Helper to handle preflights
map "\$request_method:\$cors_origin" \$cors_preflight {
  "OPTIONS:"      "not-allowed";
  "~^OPTIONS:.+"  "allowed";
  default         "";
}
EOF

# Variables used for resource `Cross-Origin-Resource-Policy`
echo "Nginx: configuring CORS resource policy with '${NGINX_CORS_RESOURCE_POLICY}'…"
cat <<EOF >> "${NGINX_CONFIG_FILE}"
# Resource policy
map "" \$cors_resource_policy {
  default "${NGINX_CORS_RESOURCE_POLICY}";
}
EOF
