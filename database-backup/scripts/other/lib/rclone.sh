#!/usr/bin/env sh

# Verify tools installed
if ! command -v rclone >/dev/null 2>&1; then
  echo >&2 'Error: rclone is not installed.' >&2
  exit 1
fi

# Constants
readonly RCLONE_CONCURRENCY=2
readonly RCLONE_CONFIG_DIR=/etc/rclone
readonly RCLONE_CONFIG_PATH="${RCLONE_CONFIG_DIR}/rclone.conf"
readonly RCLONE_CHUNK_SIZE=16M
readonly RCLONE_TIMEOUT=30s

rclone_cmd() {
  rclone --config="$RCLONE_CONFIG_PATH" $@
}

#
# === Setup ===
#

rclone_bootstrap_config() {
  mkdir -p "$RCLONE_CONFIG_DIR"
  rclone_cmd config touch >/dev/null 2>&1
  chmod a+r $RCLONE_CONFIG_PATH
}

#
# === RDB Backup Functions ===
#

# Params:
# - Source
# - Target
rclone_copy_url() {
  # Note: limit memory use by setting low concurrency & chunk size
  rclone_cmd copyurl "$1" "$2" \
    --low-level-retries 5 \
    --no-check-certificate \
    --retries 2 \
    --s3-chunk-size "$RCLONE_CHUNK_SIZE" \
    --s3-upload-concurrency "$RCLONE_CONCURRENCY" \
    --stats 4s \
    --stats-one-line \
    --stats-log-level NOTICE \
    --timeout 30s \
    --transfers 1
}
