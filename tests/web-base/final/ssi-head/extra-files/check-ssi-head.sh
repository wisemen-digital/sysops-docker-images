#!/usr/bin/env sh

set -eu

readonly TEST_DIR=$(mktemp -d /tmp/ssi-head-integration.XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

fetch() {
  wget -qO- --header "Host: $1" "http://127.0.0.1:80${2:-/}"
}

revision() {
  sed -n 's/.*<meta name="revision" content="\([^"]*\)".*/\1/p' "$1"
}

count_requests() {
  grep -c "^$1|" /tmp/ssi-head-upstream.log || true
}

assert_equal() {
  [ "$1" = "$2" ] || { echo "Assertion failed: $3" >&2; exit 1; }
}

# Unique domains keep these checks independent if goss retries the command.
readonly DOMAIN_A="a-$$.example"
readonly DOMAIN_B="b-$$.example"
fetch "$DOMAIN_A" > "$TEST_DIR/a"
fetch "$DOMAIN_B" > "$TEST_DIR/b"
grep -q "<title>$DOMAIN_A</title>" "$TEST_DIR/a"
grep -q "<title>$DOMAIN_B</title>" "$TEST_DIR/b"
grep -q 'content="||source=ssi"' "$TEST_DIR/a"

fetch "$DOMAIN_A" /index.html > "$TEST_DIR/index"
fetch "$DOMAIN_A" '/foo/bar?language=ignored' > "$TEST_DIR/deep"
assert_equal "$(revision "$TEST_DIR/a")" "$(revision "$TEST_DIR/index")" 'index uses same domain cache'
assert_equal "$(revision "$TEST_DIR/a")" "$(revision "$TEST_DIR/deep")" 'deep links and queries share cache'
assert_equal "$(count_requests "$DOMAIN_A")" 1 'cache hits do not contact upstream'

# Even on a cold cache, caller credentials and a spoofed hostname are removed.
readonly DOMAIN_HEADERS="credentials-$$.example"
wget -qO- --header "Host: $DOMAIN_HEADERS" --header 'X-Forwarded-Host: spoofed.example' \
  --header 'Cookie: browser-cookie' --header 'Authorization: Bearer browser-token' \
  http://127.0.0.1:80/ > "$TEST_DIR/credentials"
grep -q "<title>$DOMAIN_HEADERS</title>" "$TEST_DIR/credentials"
grep -q 'content="||source=ssi"' "$TEST_DIR/credentials"

# A static index must not return 304 instead of assembling current tags.
wget -S -qO "$TEST_DIR/conditional" --header "Host: $DOMAIN_A" \
  --header 'If-Modified-Since: Wed, 01 Jan 2031 00:00:00 GMT' \
  --header 'If-None-Match: *' http://127.0.0.1:80/ 2> "$TEST_DIR/headers"
grep -q 'HTTP/1.1 200' "$TEST_DIR/headers"
if grep -qiE '^[[:space:]]*(ETag|Last-Modified):' "$TEST_DIR/headers"; then
  echo 'Static validators leaked into assembled HTML' >&2
  exit 1
fi

# The mock deliberately rate-limits these responses to keep a fill in flight.
readonly DOMAIN_CONCURRENT="concurrent-$$.example"
for i in 1 2 3 4; do
  fetch "$DOMAIN_CONCURRENT" > "$TEST_DIR/concurrent-$i" &
done
wait
for i in 1 2 3 4; do
  assert_equal "$(revision "$TEST_DIR/concurrent-1")" "$(revision "$TEST_DIR/concurrent-$i")" 'concurrent visitors share one fill'
done
assert_equal "$(count_requests "$DOMAIN_CONCURRENT")" 1 'cold cache is locked'

readonly DOMAIN_REFRESH="refresh-$$.example"
fetch "$DOMAIN_REFRESH" > "$TEST_DIR/old"
sleep 6
started=$(date +%s)
fetch "$DOMAIN_REFRESH" > "$TEST_DIR/stale"
elapsed=$(( $(date +%s) - started ))
[ "$elapsed" -lt 2 ] || { echo 'Expired cache blocked on refresh' >&2; exit 1; }
assert_equal "$(revision "$TEST_DIR/old")" "$(revision "$TEST_DIR/stale")" 'expired cache serves previous tags'
for attempt in 1 2 3 4 5 6; do
  sleep 1
  fetch "$DOMAIN_REFRESH" > "$TEST_DIR/new"
  if [ "$(revision "$TEST_DIR/new")" != "$(revision "$TEST_DIR/old")" ]; then
    break
  fi
done
[ "$(revision "$TEST_DIR/new")" != "$(revision "$TEST_DIR/old")" ] \
  || { echo 'Background refresh did not update the fragment' >&2; exit 1; }

# Redirects and errors do not leak API bodies or become cached fallback content.
for prefix in error redirect disconnect; do
  domain="$prefix-$$.example"
  fetch "$domain" > "$TEST_DIR/$prefix-1"
  fetch "$domain" > "$TEST_DIR/$prefix-2"
  grep -q '<title>Fallback website</title>' "$TEST_DIR/$prefix-1"
  if grep -q 'upstream-error-body' "$TEST_DIR/$prefix-1"; then
    echo 'Upstream error body leaked into head' >&2
    exit 1
  fi
  assert_equal "$(count_requests "$domain")" 2 'failed fragments are not cached'
done

echo 'SSI head integration checks passed'
