ARG ALPINE_VERSION="3.23"
ARG SCW_VERSION="2.49"

#
# --- Stage 1: Tools ---
#

FROM scaleway/cli:${SCW_VERSION} AS scaleway

#
# --- Stage 2: Base ---
#

FROM common:${ALPINE_VERSION} AS base

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    openssh-client \
    rclone

# Install tools
COPY --from=scaleway /scw /usr/local/bin/scw

# Copy configuration files
# - init
COPY scripts/ /scripts/

#
# --- Variant: Default ---
#

FROM base AS final

# Set default command
CMD ["backup"]
