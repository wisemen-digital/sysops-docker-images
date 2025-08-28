#!/usr/bin/env sh

set -euo pipefail

# Configure PHP FPM `pm` based on ENV vars
#
# Inputs:
# - MONITOR_MEM_THRESHOLD: percentage of mem. limit, defaults to '85'
# - MONITOR_PID_NAME: name of processes to monitor, defaults to 'node'

# Set defaults
MONITOR_MEM_THRESHOLD="${MONITOR_MEM_THRESHOLD:-85}"
MONITOR_PID_NAME="${MONITOR_PID_NAME:-node}"
SLEEP_INTERVAL=10

# -- Helpers --

# Get memory limit from cgroups (bytes)
get_memory_limit() {
  if [ -f /sys/fs/cgroup/memory.max ]; then
    limit=$(cat /sys/fs/cgroup/memory.max)
    [ "$limit" = "max" ] && echo 0 || echo "$limit"
  elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
    cat /sys/fs/cgroup/memory/memory.limit_in_bytes
  else
    echo 0
  fi
}

# Get total RSS of all node processes (bytes)
get_node_rss_total() {
  total=0
  for pid in $(pidof "$MONITOR_PID_NAME" 2>/dev/null); do
    rss_kb=$(awk '/VmRSS:/ {print $2}' /proc/$pid/status 2>/dev/null)
    [ -n "$rss_kb" ] && total=$((total + rss_kb * 1024))
  done
  echo "$total"
}

# Main check function
check_usage() {
  threshold="$1"
  [ "$threshold" -eq 0 ] && return 0  # Unlimited → always pass
  total_rss=$(get_node_rss_total)

  if [ "$total_rss" -ge "$threshold" ]; then
    return 1
  fi

  return 0
}

# -- Main Loop --

limit=$(get_memory_limit)
threshold=$((limit * MONITOR_MEM_THRESHOLD / 100))
threshold_mb=$((threshold / 1024 / 1024))
echo "Monitoring '$MONITOR_PID_NAME' memory usage, threshold of ${MONITOR_MEM_THRESHOLD}% ($threshold_mb MB)"

while true; do
  if ! check_usage $threshold ; then
    echo "WARNING: memory exceeded, trying to stop gracefully…"
    exit 1
  fi
  sleep "$SLEEP_INTERVAL"
done
