#!/usr/bin/env sh

set -euo pipefail

# Configure nginx security based on ENV vars.
#
# Inputs (aside from all the individual CSP settings):
# - NGINX_CSP_REPORT_URI: defaults to ''
# - NGINX_FRAME_OPTIONS: defaults to 'deny', note that setting to `disable` removes the header completely.

# Set defaults
NGINX_CSP_REPORT_URI="${NGINX_CSP_REPORT_URI:-}"
NGINX_FRAME_OPTIONS="${NGINX_FRAME_OPTIONS:-deny}"

# Check nginx structure
if [ ! -d /etc/nginx/site-mods-enabled.d/ ]; then
  echo "Nginx: site-mods-enabled folder is missing, skipping security…"
  exit 0
fi

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
child-src ${NGINX_CSP_CHILD_SRC:-}; \
connect-src ${NGINX_CSP_CONNECT_SRC:-}; \
font-src ${NGINX_CSP_FONT_SRC:-}; \
form-action ${NGINX_CSP_FORM_ACTION:-}; \
frame-ancestors ${NGINX_CSP_FRAME_ANCESTORS:-}; \
frame-src ${NGINX_CSP_FRAME_SRC:-}; \
img-src ${NGINX_CSP_IMG_SRC:-}; \
manifest-src ${NGINX_CSP_MANIFEST_SRC:-}; \
media-src ${NGINX_CSP_MEDIA_SRC:-}; \
object-src ${NGINX_CSP_OBJECT_SRC:-}; \
require-trusted-types-for ${NGINX_CSP_REQUIRE_TRUSTED_TYPES_FOR:-}; \
script-src ${NGINX_CSP_SCRIPT_SRC:-}; \
style-src ${NGINX_CSP_STYLE_SRC:-}; \
trusted-types ${NGINX_CSP_TRUSTED_TYPES:-}; \
worker-src ${NGINX_CSP_WORKER_SRC:-}; \
report-uri ${NGINX_CSP_REPORT_URI}; \
";
EOF
