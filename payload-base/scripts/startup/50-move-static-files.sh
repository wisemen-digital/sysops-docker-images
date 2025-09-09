#!/usr/bin/env sh

set -euo pipefail

# Move static files, so we can serve `/_next/static/…`
if [ -d "/app/www/.next/static" ]; then
  if [ -d "/app/www/public" ]; then
    # Nginx root will be /app/www/public if it exists
    mv /app/www/.next /app/www/public/_next

    # LEGACY: ensure `npm start` still works
    if [ -d "./.next" ]; then
      ln -s /app/www/public/_next/static ./.next/static
    fi
  else
    # Otherwise it'll just be /app/www
    mv /app/www/.next /app/www/_next

    # LEGACY: add alias for `npm start`
    if [ -d "./.next" ]; then
      ln -s /app/www/_next/static ./.next/static
    fi
  fi
fi
