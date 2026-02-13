#!/usr/bin/env sh

set -eu

# Move static files, so we can serve `/_next/static/…`
if [ -d "/app/www/.next/static" ]; then
  if [ -d "/app/www/public" ]; then
    # Nginx root will be /app/www/public if it exists
    mv /app/www/.next /app/www/public/_next
  else
    # Otherwise it'll just be /app/www
    mv /app/www/.next /app/www/_next
  fi
fi
