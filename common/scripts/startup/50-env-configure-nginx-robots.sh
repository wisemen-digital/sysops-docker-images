#!/usr/bin/env sh

set -euo pipefail

# Configure nginx robots rules based on ENV vars
#
# Inputs:
# - NGINX_ROBOTS_TAG: defaults to 'none'
# - NGINX_ROBOTS_TXT: defaults to 'Disallow: /', note that setting to `disable` removes the rule completely.

# Set defaults
NGINX_ROBOTS_TAG="${NGINX_ROBOTS_TAG:-none}"
NGINX_ROBOTS_TXT="${NGINX_ROBOTS_TXT:-Disallow: /}"

# Check nginx structure
if [ ! -d /etc/nginx/site-mods-enabled.d/ ]; then
  exit 0
fi

# robots tag header
echo "Nginx: configuring robots tag header with '${NGINX_ROBOTS_TAG}'…"
cat <<EOF > /etc/nginx/site-mods-enabled.d/generated-robots.conf
# Configure indexing
add_header 'X-Robots-Tag' '${NGINX_ROBOTS_TAG}';
EOF

# robots.txt file
if [ "${NGINX_ROBOTS_TXT}" != 'disable' ]; then
  echo "Nginx: configuring robots.txt with '${NGINX_ROBOTS_TXT}'…"
  cat <<EOF >> /etc/nginx/site-mods-enabled.d/generated-robots.conf
# Configure crawlers
location = /robots.txt {
  add_header 'Content-Type' 'text/plain';
  return 200 "User-agent: *\n${NGINX_ROBOTS_TXT}\n";
}
EOF
fi
