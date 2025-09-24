#
# --- Stage 1: Base ---
#

ARG ALPINE_VERSION="3.22"
FROM common:${ALPINE_VERSION}-nginx AS base

# Note: version repeated below
ARG PHP_VERSION="84"  
ARG DEFAULT_TZ="Europe/Brussels"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-pcntl \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-pdo_sqlite \
    php${PHP_VERSION}-pecl-event \
    php${PHP_VERSION}-pecl-opentelemetry \
    php${PHP_VERSION}-pecl-redis \
    php${PHP_VERSION}-phar \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlreader \
    php${PHP_VERSION}-xmlwriter \
    php${PHP_VERSION}-zip \
    tzdata \
  && ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/php \
  && cp /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime \
  && echo "${DEFAULT_TZ}" > /etc/timezone \
  && apk del tzdata

# Copy configuration files
# - php
COPY config/php/ /etc/php${PHP_VERSION}/
# - s6-overlay
COPY config/s6-overlay /etc/s6-overlay/s6-rc.d/
# - init
COPY scripts/ /scripts/

# Defaults
ENV NGINX_API_PATHS=api,oauth,livewire

#
# --- Variant: Octane ---
#

FROM base AS octane
ARG PHP_VERSION="84"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    php${PHP_VERSION}-pecl-swoole \
    php${PHP_VERSION}-posix

# Copy configuration files
COPY config/nginx/http.d/default-octane.conf /etc/nginx/http.d/default.conf
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/php-octane

#
# --- Variant: FPM (default) ---
#

FROM base AS fpm
ARG PHP_VERSION="84"

# Install packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
    php${PHP_VERSION}-fpm \
  && ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm

# Copy configuration files
COPY config/nginx/http.d/default-fpm.conf /etc/nginx/http.d/default.conf
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/php-fpm
