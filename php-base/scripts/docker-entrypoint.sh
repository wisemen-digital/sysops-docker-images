#!/usr/bin/env sh

set -euo pipefail

## Bootstrap

for script in /scripts/startup/*.sh; do
  $script
done

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
  exec php artisan queue:work --verbose --tries=3 --timeout=60 --rest=0.5 --sleep=3 --max-jobs=1000 --max-time=3600  "$@"

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
