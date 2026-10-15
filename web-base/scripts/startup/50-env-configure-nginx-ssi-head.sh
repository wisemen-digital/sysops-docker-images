#!/usr/bin/env sh

set -eu

readonly HTML_CONFIG=/etc/nginx/snippets/ssi-head-html.conf
readonly CACHE_CONFIG=/etc/nginx/http.d/generated-ssi-head-cache.conf
readonly UPSTREAM_CONFIG=/etc/nginx/snippets/proxy/generated-ssi-head-upstream.conf
readonly LOCATION_CONFIG=/etc/nginx/site-mods-enabled.d/ssi-head.conf
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
    '^http://([A-Za-z0-9._-]+|\[[0-9A-Fa-f:]+\])(:[0-9]+)?(/[-A-Za-z0-9._~:/?&=%,+!*()@]*)?$' \
    || fail 'NGINX_SSI_HEAD_URL must be a literal HTTP URL without credentials or a fragment'

  # A URL without a path denotes the upstream root, not the internal SSI URI.
  case "${HEAD_URL#*://}" in
    */*) ;;
    *) HEAD_URL="$HEAD_URL/" ;;
  esac
fi

readonly HEAD_URL

if [ -n "$HEAD_URL" ]; then
  mkdir -p "$CACHE_DIR"
  chown nobody:nogroup "$CACHE_DIR"

  echo 'include /etc/nginx/snippets/ssi-head-html-enabled.conf;' > "$HTML_CONFIG"

  cat > "$CACHE_CONFIG" <<EOF
include /etc/nginx/snippets/vars/ssi-head.conf;

proxy_cache_path $CACHE_DIR levels=1:2 keys_zone=ssi_head:1m
    max_size=$CACHE_MAX_SIZE inactive=$CACHE_INACTIVE use_temp_path=off;
EOF

  cat > "$UPSTREAM_CONFIG" <<EOF
proxy_pass "$HEAD_URL";
proxy_cache_key "$HEAD_URL|\$host";
proxy_cache_valid 200 $CACHE_TTL;
EOF

  ln -sf ../site-mods-available.d/ssi-head.conf "$LOCATION_CONFIG"

  echo 'Nginx: enabled domain-aware SSI head caching'
else
  echo '# SSI head disabled' > "$HTML_CONFIG"
  echo '# SSI head disabled' > "$CACHE_CONFIG"
  echo '# SSI head disabled' > "$UPSTREAM_CONFIG"
  rm -f "$LOCATION_CONFIG"
fi
