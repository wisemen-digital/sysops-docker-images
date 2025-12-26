FROM scaleway/cli:2.49

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    bash \
    unzip \
    aws-cli

# Install backup script
COPY scripts/ /scripts/

# Set entrypoint
ENTRYPOINT ["./scripts/scw-backup.sh"]
