#!/usr/bin/env sh

set -euo pipefail

# Cache laravel config
if [ -f '/app/www/artisan' ]; then
  php artisan config:cache
fi
