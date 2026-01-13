#!/usr/bin/env sh

set -eu

# Inject environment variables
readonly ENV_EXAMPLE_PATH=/etc/import-meta-env/example
if [ -f $ENV_EXAMPLE_PATH ]; then
  echo "Found example env at '$ENV_EXAMPLE_PATH', applying to codebase…"
  import-meta-env \
    --example $ENV_EXAMPLE_PATH \
    --path '/app/www/index.html' \
    --disposable || exit 1
else
  echo 'No example env file found, skipping env import…'
fi
