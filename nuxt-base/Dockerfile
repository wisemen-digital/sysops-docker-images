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
# - supervisor
COPY config/supervisor/conf.d/ /etc/supervisor/conf.d/
# - init
COPY scripts/ /scripts/

#
# --- Variant: Unsecured ---
#

FROM base AS unsecured

RUN rm /etc/nginx/site-mods-enabled.d/headers-extra-security.conf

USER nobody

#
# --- Variant: Secure (default) ---
#

FROM base AS secure

USER nobody
