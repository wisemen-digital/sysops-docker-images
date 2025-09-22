#!/usr/bin/env sh
safe_exec php artisan migrate \
  --isolated \
  --no-interaction \
  --force
