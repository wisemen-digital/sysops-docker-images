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

# Init script, for use in initContainers (for example)
elif [ "$1" = 'init' ]; then 
  exec /scripts/bootstrap.sh

# Fallback: just execute given command
else
  exec "$@"
fi
