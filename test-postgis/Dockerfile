# hadolint ignore=DL3007
FROM postgis/postgis:latest AS final

# Copy configuration files
COPY test-postgis/config/postgresql/postgresql.conf /etc/postgresql.conf

# Start server
CMD ["postgres", "-c", "config_file=/etc/postgresql.conf"]
