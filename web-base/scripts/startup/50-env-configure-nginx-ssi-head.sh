#!/usr/bin/env sh

set -eu

readonly HTML_CONFIG=/etc/nginx/snippets/ssi-head-html.conf
readonly CACHE_CONFIG=/etc/nginx/http.d/generated-ssi-head-cache.conf
readonly LOCATION_CONFIG=/etc/nginx/site-mods-enabled.d/generated-ssi-head.conf
readonly CACHE_DIR=/tmp/ssi-head-cache
HEAD_URL=${NGINX_SSI_HEAD_URL:-}
readonly CACHE_TTL=${NGINX_SSI_HEAD_CACHE_TTL:-1h}
readonly CACHE_INACTIVE=${NGINX_SSI_HEAD_CACHE_INACTIVE:-2h}
readonly CACHE_MAX_SIZE=${NGINX_SSI_HEAD_CACHE_MAX_SIZE:-100m}

fail() {
  echo "Nginx SSI head: $1" >&2
  exit 1
}

matches() {
  # grep matches individual lines; explicitly reject multiline configuration.
  [ "$(printf '%s' "$1" | tr -d '\r\n')" = "$1" ] \
    && printf '%s\n' "$1" | LC_ALL=C grep -Eq "$2"
}

if [ -n "$HEAD_URL" ]; then
  # Reject nginx variables, credentials, fragments and configuration delimiters.
  # Percent-encode URI characters outside this deliberately small allowlist.
  matches "$HEAD_URL" \
    '^https?://([A-Za-z0-9._-]+|\[[0-9A-Fa-f:]+\])(:[0-9]+)?(/[-A-Za-z0-9._~:/?&=%,+!*()@]*)?$' \
    || fail 'NGINX_SSI_HEAD_URL must be a literal HTTP(S) URL without credentials or a fragment'
  matches "$CACHE_TTL" '^[1-9][0-9]*[smhdw]?$' \
    || fail 'NGINX_SSI_HEAD_CACHE_TTL must be a positive duration (for example 1h)'
  matches "$CACHE_INACTIVE" '^[1-9][0-9]*[smhdw]?$' \
    || fail 'NGINX_SSI_HEAD_CACHE_INACTIVE must be a positive duration (for example 2h)'
  matches "$CACHE_MAX_SIZE" '^[1-9][0-9]*[kKmMgG]?$' \
    || fail 'NGINX_SSI_HEAD_CACHE_MAX_SIZE must be a positive size (for example 100m)'

  # A URL without a path denotes the upstream root, not the internal SSI URI.
  case "${HEAD_URL#*://}" in
    */*) ;;
    *) HEAD_URL="$HEAD_URL/" ;;
  esac
fi

readonly HEAD_URL

# Reset generated configuration on every startup, including when opting out.
mkdir -p /etc/nginx/snippets /etc/nginx/http.d /etc/nginx/site-mods-enabled.d
echo '# SSI head disabled' > "$HTML_CONFIG"
rm -f "$CACHE_CONFIG" "$LOCATION_CONFIG"

if [ -z "$HEAD_URL" ]; then
  exit 0
fi

mkdir -p "$CACHE_DIR"
chown nobody:nogroup "$CACHE_DIR"

cat > "$HTML_CONFIG" <<'EOF'
ssi on;
ssi_last_modified off;
etag off;
if_modified_since off;
EOF

cat > "$CACHE_CONFIG" <<EOF
proxy_cache_path $CACHE_DIR levels=1:2 keys_zone=ssi_head:1m
    max_size=$CACHE_MAX_SIZE inactive=$CACHE_INACTIVE use_temp_path=off;

# Only successful fragments may be cached, even when an upstream sends a TTL.
map \$upstream_status \$ssi_head_do_not_cache {
  default 1;
  200 0;
}
EOF

# Normalize upstream redirects/errors to an empty fragment for SSI stubs.
# Nginx reserves 499 for closed client connections; error_page rejects it.
readonly ERROR_CODES=$(seq 300 599 | sed '/^499$/d' | tr '\n' ' ')

cat > "$LOCATION_CONFIG" <<EOF
location = /_ssi/head {
  internal;
  ssi off;

  proxy_pass "$HEAD_URL";
  proxy_method GET;
  proxy_pass_request_body off;
  proxy_pass_request_headers off;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header Accept text/html;
  proxy_set_header Accept-Encoding "";
  proxy_set_header Connection "";
  proxy_set_header Content-Length "";
  proxy_hide_header Set-Cookie;
  proxy_ignore_headers X-Accel-Redirect;

  proxy_http_version 1.1;
  proxy_buffering on;
  proxy_connect_timeout 1s;
  proxy_send_timeout 2s;
  proxy_read_timeout 2s;
  proxy_next_upstream off;
  proxy_redirect off;
  proxy_ssl_server_name on;
  proxy_ssl_verify on;
  proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;

  proxy_cache ssi_head;
  proxy_cache_key "$HEAD_URL|\$host";
  proxy_cache_valid 200 $CACHE_TTL;
  proxy_no_cache \$ssi_head_do_not_cache;
  proxy_cache_lock on;
  proxy_cache_background_update on;
  proxy_cache_use_stale updating;

  proxy_intercept_errors on;
  error_page $ERROR_CODES =204 /_ssi/head-empty;
}

location = /_ssi/head-empty {
  internal;
  return 204;
}
EOF

echo 'Nginx: enabled domain-aware SSI head caching'
