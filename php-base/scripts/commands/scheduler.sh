#!/usr/bin/env sh
exec sh -c '
  while [ true ]; do
    php artisan schedule:run --verbose --no-interaction &
    sleep 60
  done'
