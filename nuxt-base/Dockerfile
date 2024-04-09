ARG NODE_VERSION=lts
FROM node:${NODE_VERSION}-alpine as final

ARG UNSECURED

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    supervisor

# Copy configuration files
# - nginx
COPY common/config/nginx/ /etc/nginx/
COPY nuxt-base/config/nginx/http.d/ /etc/nginx/http.d/
# - supervisor
COPY common/config/supervisor/supervisord.conf /etc/supervisor/
COPY common/config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/
COPY nuxt-base/config/supervisor/conf.d/ /etc/supervisor/conf.d/
# - init
COPY nuxt-base/scripts/docker-entrypoint.sh /

# Variations
RUN if [ "${UNSECURED}" = "true" ]; then rm /etc/nginx/site-mods-enabled.d/headers-extra-security.conf; fi

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody /docker-entrypoint.sh /app/www /run /var/lib/nginx /var/log/nginx \
  && addgroup nobody tty
USER nobody
EXPOSE 8080

# Start supervisord by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]
