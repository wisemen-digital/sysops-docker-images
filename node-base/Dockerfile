#
# --- Stage 1: Base ---
#

ARG ALPINE_VERSION="3.22"
FROM common:${ALPINE_VERSION} AS base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nodejs \
    npm

# Copy configuration files
# - s6-overlay
COPY config/s6-overlay /etc/s6-overlay/s6-rc.d/
# - init
COPY scripts/ /scripts/

# Legacy, need to get rid of this at some point
EXPOSE 3000

#
# --- Variant: Default ---
#

FROM base AS final
