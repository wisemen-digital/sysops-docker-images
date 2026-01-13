#!/usr/bin/env sh

set -eu

if [ ! -e matomo.php ]; then
  tar cf - --one-file-system -C /usr/src/matomo . | tar xf -
fi
