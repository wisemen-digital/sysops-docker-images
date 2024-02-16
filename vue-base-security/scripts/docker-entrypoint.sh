#!/usr/bin/env sh

set -euo pipefail

# Inject environment variables
ENV_EXAMPLE_PATH=/etc/import-meta-env/example
if [ -f $ENV_EXAMPLE_PATH ]; then
  echo "Found example env at '$ENV_EXAMPLE_PATH', applying to codebase…"
  import-meta-env \
    --example $ENV_EXAMPLE_PATH \
    --path '/usr/share/nginx/html/**/*' \
    --disposable || exit 1
else
  echo 'No example env file found, skipping env import…'
fi

## Commands ##

# Helper to serve all services
if [ "$1" = 'serve' ]; then
  exec nginx -g 'daemon off;'

# Fallback: just execute given command
else
  exec "$@"
fi
