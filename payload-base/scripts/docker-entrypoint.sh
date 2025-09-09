#!/usr/bin/env sh

set -euo pipefail

## Bootstrap

for script in /scripts/startup/*.sh; do
  $script
done

## Commands ##

# Helper to serve all services
if [ "$1" = 'serve' ]; then
  export CURRENT_WORKING_DIRECTORY=$(pwd)
  export HOSTNAME=0.0.0.0 PORT=3000
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Helper to run workers
elif [ "$1" = 'worker' ]; then 
  shift 1;
  export IS_JOB=TRUE
  exec /usr/local/bin/node ./server.js "$@"

# Helper to run node commands
elif [ "$1" = 'node' ]; then
  shift 1;
  exec /usr/local/bin/node "$@"

# Fallback: just execute given command
else
  exec "$@"
fi
