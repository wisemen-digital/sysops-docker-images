#
# Base image for all other stacks
#

ARG ALPINE_VERSION="3.22"
FROM alpine:${ALPINE_VERSION} AS base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    supervisor

# Copy files
COPY config/supervisor/supervisord.conf /etc/supervisor/
COPY scripts /scripts/

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody \
    /app/www \
    /run \
  && addgroup nobody tty

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["serve"]

#
# --- Variant: nginx ---
#

FROM base AS nginx

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx

# Copy files
COPY config/nginx/ /etc/nginx/
COPY config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/

# Clean Up
RUN rm -f /etc/nginx/conf.d/default.conf \
  && chown -R nobody:nobody \
    /etc/nginx/site-mods-enabled.d \
    /etc/nginx/snippets/vars/ \
    /var/lib/nginx \
    /var/log/nginx

EXPOSE 8080
