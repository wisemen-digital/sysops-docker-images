#!/usr/bin/env sh

# Verify tools installed
if ! command -v rclone >/dev/null 2>&1; then
  echo >&2 'Error: rclone is not installed.' >&2
  exit 1
fi

# Constants
readonly RCLONE_CONCURRENCY=2
readonly RCLONE_CHUNK_SIZE=16M
readonly RCLONE_TIMEOUT=30s

#
# === RDB Backup Functions ===
#

# Params:
# - Source
# - Target
rclone_copy_url() {
  # Note: limit memory use by setting low concurrency & chunk size
  rclone copyurl "$1" "$2" \
    --low-level-retries 5 \
    --no-check-certificate \
    --progress \
    --retries 2 \
    --s3-chunk-size "$RCLONE_CHUNK_SIZE" \
    --s3-upload-concurrency "$RCLONE_CONCURRENCY" \
    --timeout 30s \
    --transfers 1
}
