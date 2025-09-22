#!/usr/bin/env sh
exec php artisan migrate \
  --isolated \
  --no-interaction \
  --force
