#!/usr/bin/env bash

spinner='|/-\'

start_spinner() {
  local msg="$1"
  i=0
  (
    while true; do
      printf "\r[%c] %s" "${spinner:i++%${#spinner}:1}" "$msg"
      sleep 0.1
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  local msg="$1"
  local success="${2:-true}"
  kill "$SPINNER_PID" 2>/dev/null || true
  wait "$SPINNER_PID" 2>/dev/null || true

  if [ "$success" = true ]; then
    printf "\r[✔] %s\n" "$msg"
  else
    printf "\r[✘] %s\n" "$msg"
  fi
}
