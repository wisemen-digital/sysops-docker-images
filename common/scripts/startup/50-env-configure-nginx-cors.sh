#!/usr/bin/env sh

set -euo pipefail

# Configure nginx CORS rules based on ENV vars
#
# Inputs:
# - NGINX_CORS_ORIGINS: defaults to '*'

# Set defaults & clean up (normalize, trim, …)
NGINX_CONFIG_FILE=/etc/nginx/snippets/vars/cors-origin.conf
NGINX_CORS_ORIGINS=$(echo "${NGINX_CORS_ORIGINS:-*}" \
  | sed 's/,/ /g; s/^ *//; s/ *$//; s/  */ /g')

# Check nginx structure
if [ ! -f "${NGINX_CONFIG_FILE}" ]; then
  exit 0
fi

# Variables used for `Access-Control-Allow-Origin` (and credentials)
if [ "$NGINX_CORS_ORIGINS" = "*" ]; then
  echo "Nginx: configuring CORS origin with wildcard (allow all)…"
  cat <<EOF > "${NGINX_CONFIG_FILE}"
# Allow all origins
map "\$http_origin" \$cors_origin {
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
