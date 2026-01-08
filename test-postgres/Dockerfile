ARG POSTGRES_IMAGE="16-alpine"
FROM postgres:${POSTGRES_IMAGE} AS base

# --- Stage 1: PostGIS Builder ---
FROM base AS postgis-builder
ARG POSTGIS_VERSION
ARG POSTGIS_SHA256
WORKDIR /usr/src/postgis

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN if [ -n "$POSTGIS_VERSION" ]; then \
        apk add --no-cache build-base autoconf automake libtool pkgconfig file gcc g++ make perl libxml2-dev proj-dev geos-dev gdal-dev json-c-dev protobuf-c-dev postgresql-dev clang19 clang-dev llvm19 llvm-dev --repository http://dl-cdn.alpinelinux.org/alpine/edge/main --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        && wget -q -O postgis.tar.gz "https://download.osgeo.org/postgis/source/postgis-$POSTGIS_VERSION.tar.gz" \
        && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
        && tar -xzf postgis.tar.gz --strip-components=1 \
        && ./configure CC=gcc CXX=g++ --with-raster --with-topology --without-wagyu --without-llvm \
        && make -s && make -s install; \
    else \
        echo "Skipping PostGIS build"; \
    fi

# --- Stage 2: TimescaleDB Builder ---
FROM base AS timescaledb-builder
ARG TIMESCALEDB_VERSION
ARG TIMESCALEDB_SHA256
WORKDIR /usr/src/timescaledb

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN if [ -n "$TIMESCALEDB_VERSION" ]; then \
        apk add --no-cache build-base cmake gcc clang clang-dev llvm-dev dpkg dpkg-dev util-linux-dev libc-dev coreutils openssl-dev \
        && wget -q -O timescaledb.tar.gz "https://github.com/timescale/timescaledb/archive/$TIMESCALEDB_VERSION.tar.gz" \
        && echo "$TIMESCALEDB_SHA256 *timescaledb.tar.gz" | sha256sum -c - \
        && tar -xzf timescaledb.tar.gz --strip-components=1 \
        && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" -DREGRESS_CHECKS=OFF \
        && cd build && make install; \
    else \
        echo "Skipping TimescaleDB build"; \
    fi

# --- Stage 3: Final Runtime ---
FROM base
ARG POSTGIS_VERSION
ARG TIMESCALEDB_VERSION

# hadolint ignore=DL3018
RUN if [ -n "$POSTGIS_VERSION" ]; then \
        apk add --no-cache json-c geos gdal proj protobuf-c --repository http://dl-cdn.alpinelinux.org/alpine/edge/main --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing; \
    fi \
    && if [ -n "$TIMESCALEDB_VERSION" ]; then \
        apk add --no-cache openssl; \
    fi

# Use --link to allow these to work even if the builder stages are "empty"
COPY --link --from=postgis-builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --link --from=postgis-builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY --link --from=timescaledb-builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --link --from=timescaledb-builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/

# Only enable TimescaleDB in config if it's being installed
RUN if [ -n "$TIMESCALEDB_VERSION" ]; then \
    sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample; \
    fi

# Initialization scripts
COPY ./init-postgis.sh /docker-entrypoint-initdb.d/1.postgis.sh
COPY ./init-timescaledb.sh /docker-entrypoint-initdb.d/2.timescaledb.sh
