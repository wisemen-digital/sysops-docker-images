#!/usr/bin/env sh

set -euo pipefail

# Configure nginx security based on ENV vars
#
# Inputs:
# - NGINX_CSP_CHILD_SRC: defaults to ''
# - NGINX_CSP_CONNECT_SRC: defaults to ''
# - NGINX_CSP_FONT_SRC: defaults to 'https://fonts.gstatic.com'
# - NGINX_CSP_FORM_ACTION: defaults to ''
# - NGINX_CSP_FRAME_ANCESTORS: defaults to 'none'
# - NGINX_CSP_FRAME_SRC: defaults to 'https://youtube.com https://www.youtube.com'
# - NGINX_CSP_IMG_SRC: defaults to 'https:'
# - NGINX_CSP_MANIFEST_SRC: defaults to ''
# - NGINX_CSP_MEDIA_SRC: defaults to 'https:'
# - NGINX_CSP_OBJECT_SRC: defaults to ''
# - NGINX_CSP_REPORT_URI: defaults to ''
# - NGINX_CSP_SCRIPT_SRC: defaults to ''
# - NGINX_CSP_STYLE_SRC: defaults to 'https://fonts.googleapis.com'
# - NGINX_CSP_WORKER_SRC: defaults to ''
# - NGINX_FRAME_OPTIONS: defaults to 'deny', note that setting to `disable` removes the header completely.

# Set defaults
NGINX_CSP_CHILD_SRC="${NGINX_CSP_CHILD_SRC:-}"
NGINX_CSP_CONNECT_SRC="${NGINX_CSP_CONNECT_SRC:-}"
NGINX_CSP_FONT_SRC="${NGINX_CSP_FONT_SRC:-https://fonts.gstatic.com}"
NGINX_CSP_FORM_ACTION="${NGINX_CSP_FORM_ACTION:-}"
NGINX_CSP_FRAME_ANCESTORS="${NGINX_CSP_FRAME_ANCESTORS:-'none'}"
NGINX_CSP_FRAME_SRC="${NGINX_CSP_FRAME_SRC:-https://youtube.com https://www.youtube.com}"
NGINX_CSP_IMG_SRC="${NGINX_CSP_IMG_SRC:-https:}"
NGINX_CSP_MANIFEST_SRC="${NGINX_CSP_MANIFEST_SRC:-}"
NGINX_CSP_MEDIA_SRC="${NGINX_CSP_MEDIA_SRC:-https:}"
NGINX_CSP_OBJECT_SRC="${NGINX_CSP_OBJECT_SRC:-}"
NGINX_CSP_REPORT_URI="${NGINX_CSP_REPORT_URI:-}"
NGINX_CSP_SCRIPT_SRC="${NGINX_CSP_SCRIPT_SRC:-}"
NGINX_CSP_STYLE_SRC="${NGINX_CSP_STYLE_SRC:-https://fonts.googleapis.com}"
NGINX_CSP_WORKER_SRC="${NGINX_CSP_WORKER_SRC:-}"
NGINX_FRAME_OPTIONS="${NGINX_FRAME_OPTIONS:-deny}"

if [ -d /etc/nginx/site-mods-enabled.d/ ]; then
  # nginx frame options header
  if [ "${NGINX_FRAME_OPTIONS}" != 'disable' ]; then
    echo "Nginx: configuring frame options with '${NGINX_FRAME_OPTIONS}'…"
    cat <<EOF > /etc/nginx/site-mods-enabled.d/00-generated-security.conf
add_header 'X-Frame-Options' '${NGINX_FRAME_OPTIONS}' always;
EOF
  fi

  # nginx content policy
  echo "Nginx: configuring content security policy…"
  cat <<EOF >> /etc/nginx/site-mods-enabled.d/00-generated-security.conf
add_header 'Content-Security-Policy' "\
default-src 'self'; \
child-src 'self' data: blob: ${NGINX_CSP_CHILD_SRC}; \
connect-src 'self' data: blob: ${NGINX_CSP_CONNECT_SRC}; \
font-src 'self' ${NGINX_CSP_FONT_SRC}; \
form-action 'self' ${NGINX_CSP_FORM_ACTION}; \
frame-ancestors ${NGINX_CSP_FRAME_ANCESTORS}; \
frame-src 'self' ${NGINX_CSP_FRAME_SRC}; \
img-src 'self' data: blob: ${NGINX_CSP_IMG_SRC}; \
manifest-src 'self' data: blob: ${NGINX_CSP_MANIFEST_SRC}; \
media-src 'self' ${NGINX_CSP_MEDIA_SRC}; \
object-src 'self' ${NGINX_CSP_OBJECT_SRC}; \
script-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: ${NGINX_CSP_SCRIPT_SRC}; \
style-src 'self' 'unsafe-inline' ${NGINX_CSP_STYLE_SRC}; \
worker-src 'self' data: blob: ${NGINX_CSP_WORKER_SRC}; \
report-uri ${NGINX_CSP_REPORT_URI}; \
";
EOF
fi
