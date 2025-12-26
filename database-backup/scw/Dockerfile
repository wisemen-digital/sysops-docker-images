FROM scaleway/cli:latest

# Install packages
RUN apk update && apk add --no-cache curl bash unzip aws-cli

# Install backup script
COPY scripts/ scripts/

# Set entrypoint
ENTRYPOINT ["./scripts/scw-backup.sh"]
