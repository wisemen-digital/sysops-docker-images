#!/usr/bin/env sh

set -eu

# Configure PHP FPM `pm` based on ENV vars
#
# Inputs:
# - PHP_FPM_PM: defaults to 'static'

# Set defaults
readonly PHP_FPM_PM="${PHP_FPM_PM:-static}"

# Validate input
if [ "$PHP_FPM_PM" = 'static' ]; then
  readonly PM_SNIPPET='
pm = static
pm.max_children = 5
pm.max_requests = 1000
'
elif [ "$PHP_FPM_PM" = 'ondemand' ]; then
  readonly PM_SNIPPET='
pm = ondemand
pm.max_children = 80
pm.process_idle_timeout = 30s;
pm.max_requests = 500
'
else
  echo "PHP: invalid FPM PM mode ${PHP_FPM_PM}"
  exit 1
fi

# Set PM mode
for php_config_file in /etc/php*/php-fpm.d/www.conf; do
  echo "PHP: configuring pm with '${PHP_FPM_PM}'…"
  echo "${PM_SNIPPET}" >> "$php_config_file"
done
