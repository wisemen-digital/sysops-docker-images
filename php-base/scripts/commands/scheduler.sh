#!/usr/bin/env sh
safe_exec sh -c '
  while [ true ]; do
    php artisan schedule:run --verbose --no-interaction &
    sleep 60
  done'
