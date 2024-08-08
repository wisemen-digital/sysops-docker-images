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
COPY node-base/scripts/docker-entrypoint.sh /

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody /docker-entrypoint.sh /app/www /run /var/lib/nginx /var/log/nginx \
  && addgroup nobody tty
EXPOSE 8080

# Start supervisord by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]

#
# --- Variant: Default ---
#

FROM base as final

USER nobody
