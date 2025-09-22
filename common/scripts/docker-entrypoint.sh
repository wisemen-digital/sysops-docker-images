#!/usr/bin/env sh

set -euo pipefail

# Bootstrap

# Set defaults
SECRET_DIR=/secrets

# Load secrets into env vars
if [ -d "$SECRET_DIR" ]; then
  for f in "$SECRET_DIR"/*; do
    [ -f "$f" ] || continue
    key=$(basename "$f")
    value=$(cat "$f")
    export "$key=$value"
  done
fi

for script in /scripts/startup/*.sh; do
  $script
done

# Check if command matches, otherwise fallback to executing it
COMMAND_SCRIPT="/scripts/commands/${1}.sh"
export CURRENT_WORKING_DIRECTORY="$PWD"
if [ -x "$COMMAND_SCRIPT" ]; then
  shift 1
  . "$COMMAND_SCRIPT"
else
  exec "$@"
fi
