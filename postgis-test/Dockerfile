# hadolint ignore=DL3007
FROM postgis/postgis:latest

# Copy configuration files
COPY ./config/postgresql/postgresql.conf /etc/postgresql.conf

# Start server
CMD ["postgres", "-c", "config_file=/etc/postgresql.conf"]
