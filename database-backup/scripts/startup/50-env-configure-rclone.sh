#!/usr/bin/env sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "${SCRIPT_DIR}/../other/lib/_common.sh"

# Configure rclone tool with a set of S3 credentials
#
# Inputs:
# - S3_PROVIDER: S3 provider (see https://rclone.org/s3/)
# - S3_ACCESS_KEY_ID: S3 access key
# - S3_SECRET_ACCESS_KEY: S3 secret key
# - S3_REGION: S3 region
# - S3_ENDPOINT: S3 endpoint
# - S3_STORAGE_CLASS: S3 storage class (see https://rclone.org/s3/#s3-storage-class)

# Input validation
require_env_vars S3_PROVIDER S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_REGION S3_ENDPOINT

# Create configuration, will be used by later rclone invocations
rclone config create s3-remote s3 \
  provider "$S3_PROVIDER" \
  access_key_id "$S3_ACCESS_KEY_ID" \
  secret_access_key "$S3_SECRET_ACCESS_KEY" \
  region "$S3_REGION" \
  endpoint "$S3_ENDPOINT" \
  acl private \
  storage_class "$S3_STORAGE_CLASS" >/dev/null
