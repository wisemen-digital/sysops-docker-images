FROM matomo:fpm-alpine AS final

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    s6-overlay

# Copy configuration files
# - crond
COPY matomo/config/crond/ /etc/crontabs/
# - nginx
COPY common/config/nginx/ /etc/nginx/
COPY matomo/config/nginx/http.d/ /etc/nginx/http.d/
# - s6-overlay
COPY common/config/s6-overlay matomo/config/s6-overlay /etc/s6-overlay/s6-rc.d/
# - init
COPY common/scripts/ matomo/scripts/ /scripts/

# S6-overlay configuration
ENV S6_LINUX_INIT=0
ENV S6_VERBOSITY=0

# Clean Up
EXPOSE 8080

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["serve"]
