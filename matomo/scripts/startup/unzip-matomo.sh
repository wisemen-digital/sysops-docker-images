#!/usr/bin/env sh

set -euo pipefail

if [ ! -e matomo.php ]; then
  tar cf - --one-file-system -C /usr/src/matomo . | tar xf -
fi
