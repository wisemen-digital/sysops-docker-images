FROM matomo:fpm-alpine AS final

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    supervisor

# Copy configuration files
# - crond
COPY matomo/config/crond/ /etc/crontabs/
# - nginx
COPY common/config/nginx/ /etc/nginx/
COPY matomo/config/nginx/http.d/ /etc/nginx/http.d/
# - supervisor
COPY common/config/supervisor/supervisord.conf /etc/supervisor/
COPY common/config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/
COPY matomo/config/supervisor/conf.d/ /etc/supervisor/conf.d/
# - init
COPY common/scripts/ matomo/scripts/ /scripts/

# Clean Up
EXPOSE 8080

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["serve"]
