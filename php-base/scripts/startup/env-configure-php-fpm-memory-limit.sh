#!/usr/bin/env sh

set -euo pipefail

# Configure PHP FPM memory limits based on ENV vars
#
# Inputs:
# - PHP_FPM_MEMORY_LIMIT: defaults to '256M'

# Set defaults
PHP_FPM_MEMORY_LIMIT="${PHP_FPM_MEMORY_LIMIT:-256M}"

for php_config_file in /etc/php*/php-fpm.d/www.conf; do
  # PHP memory limits
  echo "PHP: configuring memory limit with '${PHP_FPM_MEMORY_LIMIT}'…"
  cat <<EOF >> "$php_config_file"
php_admin_value[memory_limit] = ${PHP_FPM_MEMORY_LIMIT}
EOF
done
