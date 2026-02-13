#!/usr/bin/env sh

set -eu

# Set defaults
readonly SECRET_DIR=/secrets

# Helper to run a command, invoking startup scripts, dropping down to `nobody`
# user, and loading secrets into ENV.
#
# Note: this is needed because for some reason we can't use
# `/init s6-rc -up change …` to start a specific oneshot without starting all
# default services.
safe_exec() {
  /etc/s6-overlay/s6-rc.d/startup-scripts/data/run.sh
  exec su nobody -s /bin/sh -c "s6-envdir -I \"$SECRET_DIR\" $*"
}

# Check if command matches, otherwise fallback to executing it
readonly COMMAND_SCRIPT="/scripts/commands/${1}.sh"
if [ -x "$COMMAND_SCRIPT" ]; then
  shift 1
  . "$COMMAND_SCRIPT"
else
  safe_exec "$@"
fi
