#!/usr/bin/env sh

set -euo pipefail


## Bootstrap


# Apply max post envs
echo "client_max_body_size ${SERVER_POST_MAX_SIZE:-8M};" > /etc/nginx/site-mods-available.d/max-upload.conf
for php_version in /etc/php*; do
  echo "php_admin_value[post_max_size] = ${SERVER_POST_MAX_SIZE:-8M}" >> $php_version/php-fpm.d/www.conf
  echo "php_admin_value[upload_max_filesize] = ${SERVER_POST_MAX_FILESIZE:-2M}" >> $php_version/php-fpm.d/www.conf
done

# Cache laravel config
if [ -f '/app/www/artisan' ]; then
  php artisan config:cache
fi


## Commands ##


# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Helper to run artisan commands
elif [ "$1" = 'artisan' ]; then
  shift 1;
  exec php artisan "$@"

# Fallback: just execute given command
else
  exec "$@"
fi
