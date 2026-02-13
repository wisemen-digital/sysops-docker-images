#!/usr/bin/env sh

set -eu

# Configure nginx robots rules based on ENV vars
#
# Inputs:
# - NGINX_ROBOTS_TAG: defaults to 'none'
# - NGINX_ROBOTS_TXT: defaults to 'Disallow: /', note that setting to `disable` removes the rule completely.

# Set defaults
readonly NGINX_CONFIG_FILE_MODS=/etc/nginx/site-mods-enabled.d/generated-robots.conf
readonly NGINX_CONFIG_FILE_VARS=/etc/nginx/snippets/vars/robots-tag.conf
readonly NGINX_ROBOTS_TAG="${NGINX_ROBOTS_TAG:-none}"
readonly NGINX_ROBOTS_TXT="${NGINX_ROBOTS_TXT:-Disallow: /}"

# robots tag header
if [ -f "${NGINX_CONFIG_FILE_VARS}" ]; then
  echo "Nginx: configuring robots tag header with '${NGINX_ROBOTS_TAG}'…"
  cat <<EOF > "${NGINX_CONFIG_FILE_VARS}"
# Configure indexing
map "" \$x_robots_tag {
  default "${NGINX_ROBOTS_TAG}";
}
EOF
fi

# robots.txt file
if [ -d /etc/nginx/site-mods-enabled.d/ ] && [ "${NGINX_ROBOTS_TXT}" != 'disable' ]; then
  echo "Nginx: configuring robots.txt with '${NGINX_ROBOTS_TXT}'…"
  cat <<EOF > "${NGINX_CONFIG_FILE_MODS}"
# Configure crawlers
location = /robots.txt {
  add_header 'Content-Type' 'text/plain';
  return 200 "User-agent: *\n${NGINX_ROBOTS_TXT}\n";
}
EOF
fi
