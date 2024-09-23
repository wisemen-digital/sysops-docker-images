#!/usr/bin/env sh

set -euo pipefail


## Bootstrap


# Apply max post envs
echo "client_max_body_size ${SERVER_POST_MAX_SIZE:-8M};" > /etc/nginx/site-mods-available.d/max-upload.conf
for php_config_file in /etc/php*/php-fpm.d/www.conf; do
  echo "php_admin_value[post_max_size] = ${SERVER_POST_MAX_SIZE:-8M}" >> "$php_config_file"
  echo "php_admin_value[upload_max_filesize] = ${SERVER_POST_MAX_FILESIZE:-2M}" >> "$php_config_file"
done

# Cache laravel config
if [ -f '/app/www/artisan' ]; then
  php artisan config:cache
fi


## Commands ##


# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Helper to run cron jobs
elif [ "$1" = 'scheduler' ]; then 
  while [ true ]; do
    php artisan schedule:run --verbose --no-interaction &
    sleep 60
  done

# Helper to run queue jobs
elif [ "$1" = 'queue' ]; then 
  shift 1;
  exec php artisan queue:work --verbose --tries=3 --timeout=60 --max-jobs=1000 --max-time=3600  "$@"

# Helper to run websockets
elif [ "$1" = 'websockets' ]; then 
  shift 1;
  exec php artisan websockets:serve

# Init script, for use in initContainers (for example)
elif [ "$1" = 'init' ]; then 
  exec php artisan migrate --isolated --no-interaction --force

# Helper to run artisan commands
elif [ "$1" = 'artisan' ]; then
  shift 1;
  exec php artisan "$@"

# Fallback: just execute given command
else
  exec "$@"
fi
