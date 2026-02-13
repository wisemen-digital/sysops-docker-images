#!/usr/bin/env sh

# Verify tools installed
if ! command -v scw >/dev/null 2>&1; then
  echo 'Error: scw is not installed.' >&2
  exit 1
fi

# Constants
readonly SCW_BACKUP_TIMEOUT=10m0s

scw_cmd() {
  scw --output=json $@
}

#
# === RDB Backup Functions ===
#

# Params:
# - Database Instance ID
# - Database Name
# - Backup name
scw_fetch_or_create_backup() {
  result=$(scw_cmd rdb backup list \
    instance-id="$1" \
    name="$3" 2>/dev/null \
    | jq -r '.[0]?.ID // empty')

  if [ -n "$result" ]; then
    echo "${result}"
  else
    scw_cmd rdb backup create \
      instance-id="$1" \
      database-name="$2" \
      name="$3" 2>&1 \
      | jq -r '.id'
  fi
}

# Params:
# - Database Backup ID
scw_wait_on_backup() {
  scw_cmd rdb backup wait "$1" \
    timeout="$SCW_BACKUP_TIMEOUT" > /dev/null
  
  # Because stable could be error as well, do our own wait just in case
  backup_status=
  until [ "$backup_status" = 'ready' ]; do
    if ! result=$(scw_cmd rdb backup get "$1" 2>&1); then
      echo "Failed to get backup status (wait for ready): $result" >&2
      return 1
    fi

    backup_status=$(printf '%s\n' "$result" | jq -r '.status')
    case "$backup_status" in
      ready) ;;
      error) echo "Bakcup in error state!"; return 1 ;;
      *) sleep 1 ;;
    esac
  done
}

# Params:
# - Database Instance ID
# - Backup name (partial match, can be prefix)
scw_get_ready_backups() {
  scw_cmd rdb backup list \
    instance-id="$1" \
    name="$2" 2>/dev/null \
    | jq -cr '.[] | select(.status? == "ready")'
}

# Params:
# - Database Backup ID
scw_export_backup() {
  scw_cmd rdb backup export "$1" >/dev/null
}

scw_get_backup_export_url() {
  if ! result=$(scw_cmd rdb backup get "$1" 2>&1); then
    echo "Failed to get export: $result" >&2
    return 1
  fi

  printf '%s\n' "$result" | jq -r '.download_url'
}

# Params:
# - Database Backup ID
scw_delete_backup() {
  scw_cmd rdb backup delete "$1" >/dev/null 2>&1
}

# Params:
# - Database Instance ID
# - Backup name (partial match, can be prefix)
# - Sync function/command that accepts an URL
scw_sync_backups() {
  sync_callback="$3"
  scw_get_ready_backups "$1" "$2" | while read -r backup; do
    backup_id=$(echo "$backup" | jq -r '.ID')
    backup_name=$(echo "$backup" | jq -r '.name')

    # Get export URL. Note that this is not instant, we need to wait until they're finished
    echo "Exporting backup ${backup_name} (${backup_id})…"
    if ! scw_export_backup "$backup_id"; then
      echo "Failed to export backup ${backup_id}" >&2
      continue
    fi

    echo "Waiting for backup ${backup_id} to be ready…"
    scw_wait_on_backup "$backup_id"
    if ! download_url=$(scw_get_backup_export_url "$backup_id"); then
      echo "Failed to export backup ${backup_id}: ${download_url}" >&2
      continue
    fi

    # Sync it
    echo "Syncing backup ${backup_name} (${backup_id})…"
    "$sync_callback" "$download_url" "$backup_name"
    
    echo "Finished syncing backup ${backup_name} (${backup_id}). Deleting backup from provider…"

    # Delete backup
    scw_delete_backup "$backup_id"

    echo "Finished processing backup ${backup_name} (${backup_id})."
  done
}
