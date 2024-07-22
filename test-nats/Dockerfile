# hadolint ignore=DL3007
FROM nats:alpine AS final

# Start server (don't use default config, as we don't want a cluster)
CMD [ "nats-server", "--jetstream" ]
