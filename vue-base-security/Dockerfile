FROM nginx:stable-alpine

# Copy configuration files
COPY ./config/nginx/ /etc/nginx/
COPY ./scripts/docker-entrypoint.sh /

# Clean Up
WORKDIR /usr/share/nginx/html
RUN chown -R nobody:nobody /docker-entrypoint.sh

# Start nginx by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]
