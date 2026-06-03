#!/usr/bin/env sh

set -eu

export PGPASSWORD="${POSTGRESQL_PASSWORD:-$POSTGRES_PASSWORD}"
bootstrap_sql=$(mktemp)
trap 'rm -f "$bootstrap_sql"' EXIT

# Generate bootstrap SQL script
cat <<EOF >"$bootstrap_sql"
CREATE EXTENSION IF NOT EXISTS postgis CASCADE;
CREATE EXTENSION IF NOT EXISTS postgis_topology CASCADE;
EOF

# Apply script to all databases
for database in postgres template1 ${POSTGRES_DB:+$POSTGRES_DB}; do
  psql -U "$POSTGRES_USER" "$database" -f "$bootstrap_sql"
done
