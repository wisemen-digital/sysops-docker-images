#!/usr/bin/env sh

set -euo pipefail

## Commands ##

# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec nginx -g 'daemon off;'

# Fallback: just execute given command
else
  exec "$@"
fi
