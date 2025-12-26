#!/usr/bin/env sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "${SCRIPT_DIR}/lib/_common.sh"
. "${SCRIPT_DIR}/lib/rclone.sh"
. "${SCRIPT_DIR}/lib/scw.sh"

# Input validation
require_env_vars DB_INSTANCE_ID DB_NAME DB_PROVIDER S3_BUCKET S3_PATH
case "$DB_PROVIDER" in
  scw) require_env_vars SCW_ACCESS_KEY SCW_SECRET_KEY SCW_DEFAULT_ORGANIZATION_ID SCW_DEFAULT_PROJECT_ID SCW_DEFAULT_REGION ;;
  *) ;;
esac

# Constants
readonly BACKUP_NAME_PREFIX="w_automated_"
readonly BACKUP_NAME="${BACKUP_NAME_PREFIX}${DB_NAME}_$(date -u +%Y%m%dT%H)"
readonly RCLONE_TARGET="s3-remote:${S3_BUCKET}/${S3_PATH}"

#
# === Main ===
#

case "$DB_PROVIDER" in
  scw)
    # Create (or fetch existing) backup
    echo "Creating (or fetching) backup…"
    if ! backup_id=$(scw_fetch_or_create_backup "$DB_INSTANCE_ID" "$DB_NAME" "$BACKUP_NAME"); then
      echo "Failed to create backup: ${backup_id}" >&2
      exit 1
    fi
    echo "Waiting for backup ${backup_id} to be ready…"
    scw_wait_on_backup "$backup_id"

    # Sync all pending backups (can be more than 1 if resuming)
    echo "Syncing backups…"
    sync_using_rclone() {
      filename="${2#$BACKUP_NAME_PREFIX}.custom"
      rclone_copy_url "$1" "${RCLONE_TARGET}/${filename}"
    }
    scw_sync_backups "$DB_INSTANCE_ID" "$BACKUP_NAME_PREFIX" sync_using_rclone
    ;;
  *)
    echo "Unknown database provider ${DB_PROVIDER}" >&2
    exit 1
    ;;
esac

# Ping heartbeat webhook if configured and backup succeeded
if [ -n "${HEARTBEAT_URL-}" ]; then
  send_heartbeat "$HEARTBEAT_URL"
fi
