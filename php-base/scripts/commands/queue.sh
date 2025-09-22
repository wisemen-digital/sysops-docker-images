#!/usr/bin/env sh
safe_exec php artisan queue:work \
  --verbose \
  --tries=3 \
  --timeout=60 \
  --rest=0.5 \
  --sleep=3 \
  --max-jobs=1000 \
  --max-time=3600 \
  "$@"
