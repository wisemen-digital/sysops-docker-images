#!/usr/bin/env sh

set -euo pipefail

# Set defaults
SECRET_DIR=/secrets

# Correct permissions so we can run as `nobody`
EXTRA_DIRS=
[ -d /var/lib/nginx ] && EXTRA_DIRS="$EXTRA_DIRS /var/lib/nginx"
[ -d /var/log/nginx ] && EXTRA_DIRS="$EXTRA_DIRS /var/log/nginx"
chown nobody:nogroup \
  /dev/stdout \
  /dev/stderr \
  /run \
  $EXTRA_DIRS

# Ensure our working path is correct
OLD_PWD="$PWD"
if [ -d /app/www ]; then
  cd /app/www
fi

# Execute individual startup scripts
for script in /scripts/startup/*.sh; do
  s6-envdir -I "$SECRET_DIR" $script
done

# Cleanup
cd "$OLD_PWD"
