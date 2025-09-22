#!/usr/bin/env sh

set -euo pipefail

# Bootstrap

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
