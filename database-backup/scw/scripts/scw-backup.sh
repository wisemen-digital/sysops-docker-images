#!/usr/bin/env bash
source ./scripts/helper.sh

set -euo pipefail

# Setup AWS CLI for S3-compatible storage
aws configure set aws_access_key_id $S3_ACCESS_KEY_ID
aws configure set aws_secret_access_key $S3_SECRET_ACCESS_KEY
aws configure set default.region $S3_REGION

BACKUP_NAME="${DB_NAME}_$(date -u +%Y%m%dT%H%M%SZ)"
FAILED=0
ERROR_MSG=""

# Create backup
if ! BACKUP_ID=$(/scw rdb backup create \
  instance-id="$DB_INSTANCE_ID" \
  database-name="$DB_NAME" \
  name="$BACKUP_NAME" \
  -o template="{{ .ID }}" 2>&1); then
  ERROR_MSG="Failed to create backup: $BACKUP_ID"
  echo "$ERROR_MSG"
  FAILED=1
else
  echo "Created backup with ID: $BACKUP_ID"
fi

# Wait for backup to be ready
if [ "$FAILED" -eq 0 ]; then
  start_spinner "Waiting for backup to be ready..."
  while true; do
    STATUS=$(/scw rdb backup get "$BACKUP_ID" \
      -o template='{{ .Status }}' 2>/dev/null || echo "creating")

    if [[ "$STATUS" == "ready" ]]; then
      break
    fi
    sleep 1
  done
  stop_spinner "Backup is ready"
fi

# Wait for export to be ready
if [ "$FAILED" -eq 0 ]; then
  start_spinner "Preparing backup export..."
  while true; do
    STATUS=$(/scw rdb backup export "$BACKUP_ID" \
      -o template='{{ .Status }}' 2>/dev/null || echo "creating")

    if [[ "$STATUS" == "ready" ]]; then
      break
    fi
    sleep 1
  done
  stop_spinner "Backup export is ready"
fi

# Download URL
if [ "$FAILED" -eq 0 ]; then
  DOWNLOAD_URL=$(/scw rdb backup export "$BACKUP_ID" \
    -o template='{{ .DownloadURL }}')
fi

# Stream upload to S3 with spinner
if [ "$FAILED" -eq 0 ]; then
  start_spinner "Uploading backup to S3..."
  set +e
  UPLOAD_OUTPUT=$(curl -s "$DOWNLOAD_URL" | \
    aws s3 cp - \
      "s3://$S3_BUCKET/$S3_PATH/$BACKUP_NAME.custom" \
      --storage-class $S3_STORAGE_CLASS --endpoint-url $S3_ENDPOINT 2>&1)
  UPLOAD_EXIT_CODE=$?
  set -e

  if [ $UPLOAD_EXIT_CODE -ne 0 ]; then
    ERROR_MSG="Failed to upload backup to S3: $UPLOAD_OUTPUT"
    stop_spinner "Failed to upload backup to S3" false
    FAILED=1
  else
    stop_spinner "Backup uploaded to s3://$S3_BUCKET/$S3_PATH/$BACKUP_NAME.custom"
  fi
fi

# Delete backup and wait until it's gone (always run if backup created)
if [ -n "${BACKUP_ID-}" ]; then
  start_spinner "Deleting backup from Scaleway..."
  /scw rdb backup delete "$BACKUP_ID" > /dev/null 2>&1 || true

  while true; do
    if scw rdb backup get "$BACKUP_ID" > /dev/null 2>&1; then
      sleep 1
    else
      break
    fi
  done
  stop_spinner "Deleted backup from Scaleway with Backup ID: $BACKUP_ID"
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Backup job failed."
  if [ -n "$ERROR_MSG" ]; then
    echo "Error details: $ERROR_MSG"
  fi
  exit 1
fi

# Ping heartbeat webhook if configured and backup succeeded
if [ -n "${HEARTBEAT_URL-}" ]; then
  start_spinner "Sending heartbeat ping..."
  if curl -fsS --retry 3 "$HEARTBEAT_URL" > /dev/null 2>&1; then
    stop_spinner "Heartbeat ping successful"
  else
    stop_spinner "Heartbeat ping failed" false
    echo "Warning: Failed to send heartbeat ping to $HEARTBEAT_URL"
  fi
fi

exit 0
