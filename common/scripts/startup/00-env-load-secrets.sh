#!/usr/bin/env sh

set -euo pipefail

# Load secrets into ENV vars
#
# Inputs:
# - SECRET_DIR: defaults to '/secrets'

# Set defaults
SECRET_DIR=${SECRET_DIR:-/secrets}

# Check folders
if [ ! -d "$SECRET_DIR" ]; then
  echo "Secret directory $SECRET_DIR does not exist"
  exit 0
fi

# Load secrets into env vars
for f in "$SECRET_DIR"/*; do
  [ -f "$f" ] || continue
  key=$(basename "$f")
  value=$(cat "$f")
  export "$key=$value"
done

# Give some info
echo "Loaded $(ls -1 "$SECRET_DIR" | wc -l) secrets from $SECRET_DIR"
