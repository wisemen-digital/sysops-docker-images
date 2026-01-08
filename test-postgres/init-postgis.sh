#!/bin/sh

set -e

create_sql=`mktemp`

cat <<EOF >${create_sql}
CREATE EXTENSION IF NOT EXISTS postgis CASCADE;
CREATE EXTENSION IF NOT EXISTS postgis_topology CASCADE;
EOF

if [ -z "${POSTGRESQL_PASSWORD:-}" ]; then
	POSTGRESQL_PASSWORD=${POSTGRES_PASSWORD:-}
fi
export PGPASSWORD="$POSTGRESQL_PASSWORD"

# Create PostGIS extensions in initial databases
psql -U "${POSTGRES_USER}" postgres -f ${create_sql}
psql -U "${POSTGRES_USER}" template1 -f ${create_sql}

if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
    psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -f ${create_sql}
fi
