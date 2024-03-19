#
# --- Stage 1: Build ---
#

FROM node:lts as build

# Build import env tool
WORKDIR /app
RUN npm i @import-meta-env/cli && \
    npx pkg ./node_modules/@import-meta-env/cli/bin/import-meta-env.js \
      -t latest-alpine \
      -o import-meta-env

#
# --- Stage 2: Run ---
#

FROM nginx:stable-alpine as final

ARG UNSECURED

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    supervisor

# Copy configuration files
# - nginx
COPY common/config/nginx/ /etc/nginx/
COPY web-base/config/nginx/http.d/ /etc/nginx/http.d/
RUN rm -f /etc/nginx/conf.d/default.conf
# - supervisor
COPY common/config/supervisor/supervisord.conf /etc/supervisor/
COPY common/config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/
# - init
COPY web-base/scripts/docker-entrypoint.sh /
COPY --from=build /app/import-meta-env /usr/bin/import-meta-env

# Variations
RUN if [ "${UNSECURED}" = "true" ]; then rm /etc/nginx/site-mods-enabled.d/headers-extra-security.conf; fi

# Clean Up
WORKDIR /app/www
EXPOSE 80

# Start supervisord by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]
