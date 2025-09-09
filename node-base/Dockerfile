#
# --- Stage 1: Base ---
#

ARG NODE_VERSION=lts
FROM node:${NODE_VERSION}-alpine as base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    supervisor

# Copy configuration files
# - nginx
COPY common/config/nginx/ /etc/nginx/
COPY node-base/config/nginx/http.d/ /etc/nginx/http.d/
# - supervisor
COPY common/config/supervisor/supervisord.conf /etc/supervisor/
COPY common/config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/
COPY node-base/config/supervisor/conf.d/ /etc/supervisor/conf.d/
# - init
COPY common/scripts/ node-base/scripts/ /scripts/

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody \
    /app/www \
    /etc/nginx/site-mods-enabled.d \
    /run \
    /var/lib/nginx \
    /var/log/nginx \
  && addgroup nobody tty
EXPOSE 8080

# Start supervisord by default
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["serve"]

#
# --- Variant: Default ---
#

FROM base as final

USER nobody
