#!/usr/bin/env sh

set -euo pipefail


## Commands ##


# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Helper to run cron jobs
elif [ "$1" = 'scheduler' ]; then 
  shift 1;
  exec /usr/local/bin/node ./dist/src/entrypoints/cronjob.js "$@"

# Helper to run workers
elif [ "$1" = 'worker' ]; then 
  shift 1;
  exec /usr/local/bin/node ./dist/src/entrypoints/worker.js "$@"

# Helper to run node commands
elif [ "$1" = 'node' ]; then
  shift 1;
  exec /usr/local/bin/node "$@"

# Fallback: just execute given command
else
  exec "$@"
fi
