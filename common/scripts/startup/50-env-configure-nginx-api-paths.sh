#!/usr/bin/env sh

set -eu

# Configure nginx CORS rules based on ENV vars
#
# Inputs:
# - NGINX_API_PATHS: defaults to '' (empty list)

# Set defaults & clean up (normalize, trim, …)
readonly NGINX_CONFIG_FILE=/etc/nginx/site-mods-enabled.d/generated-api-paths.conf
readonly NGINX_API_PATHS=$(echo "${NGINX_API_PATHS:-}" \
  | sed 's/,/ /g; s/^ *//; s/ *$//; s/  */ /g')

# Check nginx structure
if [ ! -d /etc/nginx/site-mods-enabled.d/ ]; then
  exit 0
fi

# Generate location blocks
echo "Nginx: configuring API paths with '${NGINX_API_PATHS}'…"
echo "# Point API paths to API bucket" > "${NGINX_CONFIG_FILE}"
for item in $NGINX_API_PATHS; do
  echo "location ~ ^/${item}/ { try_files \$uri @api_backend; }" >> "${NGINX_CONFIG_FILE}"
done
