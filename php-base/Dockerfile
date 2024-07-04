#
# --- Stage 1: Base ---
#

ARG ALPINE_VERSION="3.19"
FROM alpine:${ALPINE_VERSION} AS base
# Note: version repeated below
ARG PHP_VERSION="83"  
ARG DEFAULT_TZ="Europe/Brussels"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-pdo_sqlite \
    php${PHP_VERSION}-pecl-redis \
    php${PHP_VERSION}-phar \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlwriter \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    supervisor \
    tzdata \
  && ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/php \
  && cp /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime \
  && echo "${DEFAULT_TZ}" > /etc/timezone \
  && apk del tzdata

# Copy configuration files
# - nginx
COPY common/config/nginx/ /etc/nginx/
RUN rm -f /etc/nginx/http.d/default.conf \
  && rm -f /etc/nginx/site-mods-enabled.d/headers-*.conf \
  && rm -f /etc/nginx/site-mods-enabled.d/cache-static-content.conf
# - php
COPY php-base/config/php/ /etc/php${PHP_VERSION}/
# - supervisor
COPY common/config/supervisor/supervisord.conf /etc/supervisor/
COPY common/config/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/
# - init
COPY php-base/scripts/docker-entrypoint.sh /

# Clean Up
WORKDIR /app/www
RUN chown -R nobody:nobody /docker-entrypoint.sh /app/www /run /var/lib/nginx /var/log/nginx /etc/nginx/site-mods-available.d/max-upload.conf /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
  && addgroup nobody tty
EXPOSE 8080

# Start supervisord by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]

#
# --- Variant: Octane ---
#

FROM base AS octane
ARG PHP_VERSION="83"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    php${PHP_VERSION}-pcntl \
    php${PHP_VERSION}-pecl-swoole \
    php${PHP_VERSION}-posix

# Copy configuration files
COPY php-base/config/nginx/http.d/default-octane.conf /etc/nginx/http.d/default.conf
COPY php-base/config/supervisor/conf.d/php-octane.conf /etc/supervisor/conf.d/

USER nobody

#
# --- Variant: FPM (default) ---
#

FROM base AS fpm
ARG PHP_VERSION="83"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    php${PHP_VERSION}-fpm \
  && ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm

# Copy configuration files
COPY php-base/config/nginx/http.d/default-fpm.conf /etc/nginx/http.d/default.conf
COPY php-base/config/supervisor/conf.d/php-fpm.conf /etc/supervisor/conf.d/

USER nobody
