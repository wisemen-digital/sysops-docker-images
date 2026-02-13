#!/usr/bin/env bash

# Fail on first error
set -eu

# Verify tools installed
if ! command -v curl >/dev/null 2>&1; then
  echo >&2 'Error: curl is not installed.'
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo >&2 'Error: jq is not installed.'
  exit 1
fi

#
# === General Helper Functions ===
#

# Params:
# List of ENV var names
require_env_vars() {
  for var in "$@"; do
    eval "value=\${$var}"
    [ -n "$value" ] || {
      echo "Error: $var is required" >&2
      exit 1
    }
  done
}

# Params:
# - Heartbeat URL
send_heartbeat() {
  if curl -fsS --retry 3 "$1" > /dev/null 2>&1; then
    echo "Heartbeat ping successful"
  else
    echo "Warning: Failed to send heartbeat ping to ${1}" >&2
  fi
}
