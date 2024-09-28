#!/usr/bin/env sh

set -euo pipefail


## Bootstrap


if [ ! -e matomo.php ]; then
  tar cf - --one-file-system -C /usr/src/matomo . | tar xf -
fi


## Commands ##


# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Init script, for use in initContainers (for example)
elif [ "$1" = 'init' ]; then 
  exec /bootstrap.sh

# Fallback: just execute given command
else
  exec "$@"
fi
