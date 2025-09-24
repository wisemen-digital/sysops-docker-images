#
# --- Stage 1: Base ---
#

ARG ALPINE_VERSION="3.22"
FROM common:${ALPINE_VERSION}-nginx AS base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nodejs \
    npm

# Copy configuration files
# - nginx
COPY config/nginx/http.d/ /etc/nginx/http.d/
# - s6-overlay
COPY config/s6-overlay /etc/s6-overlay/s6-rc.d/
# - init
COPY scripts/ /scripts/

# Defaults
ENV NGINX_API_PATHS=api

#
# --- Variant: Unsecured ---
#

FROM base AS unsecured

RUN rm /etc/nginx/site-mods-enabled.d/headers-extra-security.conf

#
# --- Variant: Secure (default) ---
#

FROM base AS secure
