#!/usr/bin/env sh

set -euo pipefail

# Prep. nginx config files so memory monitor service can disable probes

if [ -d /etc/nginx/site-mods-enabled.d/ ]; then
  NGINX_CONFIG_FILE=/etc/nginx/snippets/nuxt-probes-content.conf

  # Default nginx config (i.e. just forward to API)
  cat <<EOF > "$NGINX_CONFIG_FILE"
try_files \$uri @api_backend;
EOF

  # Give access to monitor process
  chmod a+w "$NGINX_CONFIG_FILE"
fi
