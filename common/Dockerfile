#
# Base image for all other stacks
#

ARG ALPINE_VERSION="3.22"
FROM alpine:${ALPINE_VERSION} AS base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    s6-overlay

# Copy files
COPY config/s6-overlay /etc/s6-overlay/s6-rc.d/
COPY scripts /scripts/

# S6-overlay configuration
ENV S6_LINUX_INIT=0
ENV S6_VERBOSITY=0
ENV S6_KILL_GRACETIME=1000

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody /app/www \
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

# Remove unneeded nginx site and enable service
RUN rm -f /etc/nginx/conf.d/default.conf \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx

EXPOSE 8080
