ARG POSTGRES_IMAGE="16-alpine"

FROM postgres:${POSTGRES_IMAGE}

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG POSTGIS_VERSION
ARG POSTGIS_SHA256
ARG TIMESCALEDB_VERSION
ARG TIMESCALEDB_SHA256

# ---- Install PostGIS from source ----
# hadolint ignore=DL3018
RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
        bash curl wget tar ca-certificates git \
    && apk add --no-cache --virtual .build-deps \
        build-base autoconf automake libtool pkgconfig file \
        gcc g++ make perl \
        libxml2-dev proj-dev geos-dev gdal-dev json-c-dev protobuf-c-dev \
        postgresql-dev clang clang-dev clang19 \
        llvm19 llvm-dev \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    && apk add --no-cache --virtual .postgis-rundeps \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        json-c \
        geos \
        gdal \
        proj \
        protobuf-c \
    \
    && mkdir -p /usr/src/postgis \
    && wget --progress=dot:giga -O /usr/src/postgis/postgis.tar.gz "https://download.osgeo.org/postgis/source/postgis-$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 */usr/src/postgis/postgis.tar.gz" | sha256sum -c - \
    && tar -xzf /usr/src/postgis/postgis.tar.gz -C /usr/src/postgis --strip-components=1 \
    && rm /usr/src/postgis/postgis.tar.gz

WORKDIR /usr/src/postgis
RUN ./configure CC=gcc CXX=g++ --with-raster --with-topology --without-wagyu --without-llvm \
    && make -s \
    && make -s install

WORKDIR /
RUN rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps

# ---- Install TimescaleDB from source ----
# hadolint ignore=DL3018
RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps-ts \
        wget tar build-base cmake \
    && apk add --no-cache --virtual .build-deps-ts \
        gcc clang clang-dev llvm-dev dpkg dpkg-dev util-linux-dev libc-dev coreutils \
    && apk add --no-cache --virtual .timescaledb-rundeps \
        openssl openssl-dev \
    \
    && mkdir -p /usr/src/timescaledb \
    && wget --progress=dot:giga -O /usr/src/timescaledb/timescaledb.tar.gz "https://github.com/timescale/timescaledb/archive/$TIMESCALEDB_VERSION.tar.gz" \
    && echo "$TIMESCALEDB_SHA256 */usr/src/timescaledb/timescaledb.tar.gz" | sha256sum -c - \
    && tar -xzf /usr/src/timescaledb/timescaledb.tar.gz -C /usr/src/timescaledb --strip-components=1 \
    && rm /usr/src/timescaledb/timescaledb.tar.gz

WORKDIR /usr/src/timescaledb
RUN ./bootstrap -DPROJECT_INSTALL_METHOD="docker" -DREGRESS_CHECKS=OFF

WORKDIR /usr/src/timescaledb/build
RUN make install

WORKDIR /
RUN rm -rf /usr/src/timescaledb \
    && apk del .fetch-deps-ts .build-deps-ts \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/local/share/postgresql/postgresql.conf.sample

# ---- Copy initialization scripts ----
COPY ./init-postgis.sh /docker-entrypoint-initdb.d/1.postgis.sh
COPY ./init-timescaledb.sh /docker-entrypoint-initdb.d/2.timescaledb.sh
COPY ./init-postgres.sh /docker-entrypoint-initdb.d/3.postgres.sh
