#
# --- Stage 1: Base ---
#

ARG POSTGRES_IMAGE="16-alpine"
FROM postgres:${POSTGRES_IMAGE} AS base

#
# --- Stage 2: PostGIS Builder ---
#

FROM base AS postgis-builder
ARG POSTGIS_VERSION
ARG POSTGIS_SHA256

WORKDIR /usr/src/postgis
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    clang-dev \
    clang19 \
    file \
    g++ \
    gcc \
    gdal-dev \
    geos-dev \
    json-c-dev \
    libtool \
    libxml2-dev \
    llvm-dev \
    llvm19 \
    make \
    perl \
    pkgconfig \
    postgresql-dev \
    proj-dev \
    protobuf-c-dev \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  && wget -q -O postgis.tar.gz "https://download.osgeo.org/postgis/source/postgis-$POSTGIS_VERSION.tar.gz" \
  && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
  && tar -xzf postgis.tar.gz --strip-components=1 \
  && ./configure CC=gcc CXX=g++ --with-raster --with-topology --without-wagyu --without-llvm \
  && make -s && make -s install

#
# --- Stage 3: TimescaleDB Builder ---
#

FROM base AS timescaledb-builder
ARG TIMESCALEDB_VERSION
ARG TIMESCALEDB_SHA256

WORKDIR /usr/src/timescaledb
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk add --no-cache \
    build-base \
    clang \
    clang-dev \
    cmake \
    coreutils \
    dpkg \
    dpkg-dev \
    gcc \
    libc-dev \
    llvm-dev \
    openssl-dev \
    util-linux-dev \
  && wget -q -O timescaledb.tar.gz "https://github.com/timescale/timescaledb/archive/$TIMESCALEDB_VERSION.tar.gz" \
  && echo "$TIMESCALEDB_SHA256 *timescaledb.tar.gz" | sha256sum -c - \
  && tar -xzf timescaledb.tar.gz --strip-components=1 \
  && ./bootstrap -DPROJECT_INSTALL_METHOD="docker" -DREGRESS_CHECKS=OFF

WORKDIR /usr/src/timescaledb/build
RUN make install

#
# --- Variant: Bare ---
#

FROM base AS bare

#
# --- Variant: PostGIS ---
#

FROM base AS postgis

# hadolint ignore=DL3018
RUN apk add --no-cache \
    gdal \
    geos \
    json-c \
    proj \
    protobuf-c \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing

COPY --from=postgis-builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=postgis-builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY ./scripts/init/1.postgis.sh /docker-entrypoint-initdb.d/

#
# --- Variant: PostGIS + TimescaleDB ---
#

FROM postgis AS postgis-timescaledb

# hadolint ignore=DL3018
RUN apk add --no-cache openssl

COPY --from=timescaledb-builder /usr/local/lib/postgresql/ /usr/local/lib/postgresql/
COPY --from=timescaledb-builder /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY ./scripts/init/2.timescaledb.sh /docker-entrypoint-initdb.d/

RUN sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample;
