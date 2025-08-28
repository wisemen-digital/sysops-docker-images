#!/usr/bin/env sh

set -euo pipefail

# Configure nginx & PHP upload limits based on ENV vars
#
# Inputs:
# - NGINX_MAX_BODY_SIZE: defaults to '8M'
# - PHP_POST_MAX_SIZE: defaults to $NGINX_MAX_BODY_SIZE (should match that value)
# - PHP_POST_MAX_FILESIZE: defaults to '2M'

# Set defaults
NGINX_MAX_BODY_SIZE="${NGINX_MAX_BODY_SIZE:-8M}"
PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE:-$NGINX_MAX_BODY_SIZE}"
PHP_POST_MAX_FILESIZE="${PHP_POST_MAX_FILESIZE:-2M}"

if [ -d /etc/nginx/site-mods-enabled.d/ ]; then
  # nginx body size
  echo "Nginx: configuring max body size with '${NGINX_MAX_BODY_SIZE}'…"
  cat <<EOF > /etc/nginx/site-mods-enabled.d/generated-max-upload.conf
client_max_body_size ${NGINX_MAX_BODY_SIZE};
EOF
fi

for php_config_file in /etc/php*/php-fpm.d/www.conf; do
  # PHP upload limits
  echo "PHP: configuring max upload with '${PHP_POST_MAX_SIZE}'…"
  cat <<EOF >> "$php_config_file"
php_admin_value[post_max_size] = ${PHP_POST_MAX_SIZE}
EOF
  echo "PHP: configuring max file upload with '${PHP_POST_MAX_FILESIZE}'…"
  cat <<EOF >> "$php_config_file"
php_admin_value[upload_max_filesize] = ${PHP_POST_MAX_FILESIZE}
EOF
done
