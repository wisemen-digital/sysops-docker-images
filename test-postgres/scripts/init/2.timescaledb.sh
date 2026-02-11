#!/usr/bin/env sh

set -eu

export PGPASSWORD="${POSTGRESQL_PASSWORD:-$POSTGRES_PASSWORD}"
POSTGRESQL_CONF_DIR="${POSTGRESQL_CONF_DIR:-$PGDATA}"
bootstrap_sql=$(mktemp)
trap 'rm -f "$bootstrap_sql"' EXIT

# Configure TimescaleDB telemetry
echo "timescaledb.telemetry_level=${TIMESCALEDB_TELEMETRY:-basic}" >> ${POSTGRESQL_CONF_DIR}/postgresql.conf

# Generate bootstrap SQL script
cat <<EOF >"$bootstrap_sql"
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
EOF
if [ "${TIMESCALEDB_TELEMETRY:-}" = "off" ]; then
  # We delete the job as well to ensure that we do not spam the
  # log with other messages related to the Telemetry job.
  cat <<EOF >>"$bootstrap_sql"
SELECT alter_job(1,scheduled:=false);
EOF
fi

# Apply script to all databases
for database in postgres template1 ${POSTGRES_DB:+$POSTGRES_DB}; do
  psql -U "$POSTGRES_USER" "$database" -f "$bootstrap_sql"
done
