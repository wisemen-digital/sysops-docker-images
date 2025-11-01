#
# --- Stage 1: Build ---
#

ARG ALPINE_VERSION="3.22"
FROM node:lts AS build

# Build import env tool
WORKDIR /app
RUN npm i @import-meta-env/cli && \
    npx pkg ./node_modules/@import-meta-env/cli/bin/import-meta-env.js \
      -t latest-alpine \
      -o import-meta-env

#
# --- Stage 2: Base ---
#

FROM common:${ALPINE_VERSION}-nginx AS base

# Copy configuration files
# - nginx
COPY config/nginx/http.d/ /etc/nginx/http.d/
# - s6-overlay
COPY config/s6-overlay /etc/s6-overlay/s6-rc.d/
# - init
COPY scripts/ /scripts/
COPY --from=build /app/import-meta-env /usr/bin/import-meta-env

# Legacy, need to get rid of this at some point, see also nginx file
EXPOSE 80

#
# --- Variant: Default ---
#

FROM base AS final
