#!/usr/bin/env sh

set -euo pipefail

# Configure nginx security based on ENV vars, and if available the defaults
# located at `/etc/csp-generator/default`.
#
# The defaults file should be a list of variable declarations, such as
# `CHILD_SRC="…"`. Essentially 1 variable for each option that exists. Be
# careful about using quotes though! Keywords such as `none` need to be
# surrounded by single `'` quotes, so the value would be `"'none'"`.
#
# Equivalent settings can be set via ENV, just prefix the variables with
# `NGINX_CSP_…`, like `NGINX_CSP_CHILD_SRC`.
#
# Inputs (aside from all the individual CSP settings):
# - NGINX_CSP_MODE: defaults to 'enforce'
# - NGINX_CSP_REPORT_URI: defaults to ''
# - NGINX_FRAME_OPTIONS: defaults to 'deny', note that setting to `disable` removes the header completely.

# Set defaults
NGINX_CSP_MODE="${NGINX_CSP_MODE:-enforce}"
NGINX_CSP_REPORT_URI="${NGINX_CSP_REPORT_URI:-}"
NGINX_FRAME_OPTIONS="${NGINX_FRAME_OPTIONS:-deny}"

# Validate input
if [ "${NGINX_CSP_MODE}" = 'enforce' ]; then
  NGINX_CSP_HEADER_NAME='Content-Security-Policy'
elif [ "${NGINX_CSP_MODE}" = 'report-only' ]; then
  NGINX_CSP_HEADER_NAME='Content-Security-Policy-Report-Only'
else
  echo "Nginx: invalid CSP mode ${NGINX_CSP_MODE}"
  exit 1
fi

# Check nginx structure
if [ ! -d /etc/nginx/site-mods-enabled.d/ ]; then
  echo "Nginx: site-mods-enabled folder is missing, skipping security…"
  exit 0
fi

# Load embedded CSP values from file (if it exists)
EMBEDDED_CSP_PATH=/etc/csp-generator/default
if [ -f "${EMBEDDED_CSP_PATH}" ]; then
  echo "Nginx: found CSP defaults at '$EMBEDDED_CSP_PATH', processing…"
  PROCESSED_CSP_PATH=$(mktemp)
  sed 's/[^=]\+=/EMBEDDED_CSP_&/' "${EMBEDDED_CSP_PATH}" > "${PROCESSED_CSP_PATH}"
  cat $PROCESSED_CSP_PATH
  source "${PROCESSED_CSP_PATH}"
  rm "${PROCESSED_CSP_PATH}"
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
add_header '${NGINX_CSP_HEADER_NAME}' "\
default-src 'self'; \
child-src ${EMBEDDED_CSP_CHILD_SRC:-} ${NGINX_CSP_CHILD_SRC:-}; \
connect-src ${EMBEDDED_CSP_CONNECT_SRC:-} ${NGINX_CSP_CONNECT_SRC:-}; \
font-src ${EMBEDDED_CSP_FONT_SRC:-} ${NGINX_CSP_FONT_SRC:-}; \
form-action ${EMBEDDED_CSP_FORM_ACTION:-} ${NGINX_CSP_FORM_ACTION:-}; \
frame-ancestors ${EMBEDDED_CSP_FRAME_ANCESTORS:-} ${NGINX_CSP_FRAME_ANCESTORS:-}; \
frame-src ${EMBEDDED_CSP_FRAME_SRC:-} ${NGINX_CSP_FRAME_SRC:-}; \
img-src ${EMBEDDED_CSP_IMG_SRC:-} ${NGINX_CSP_IMG_SRC:-}; \
manifest-src ${EMBEDDED_CSP_MANIFEST_SRC:-} ${NGINX_CSP_MANIFEST_SRC:-}; \
media-src ${EMBEDDED_CSP_MEDIA_SRC:-} ${NGINX_CSP_MEDIA_SRC:-}; \
object-src ${EMBEDDED_CSP_OBJECT_SRC:-} ${NGINX_CSP_OBJECT_SRC:-}; \
require-trusted-types-for ${EMBEDDED_CSP_REQUIRE_TRUSTED_TYPES_FOR:-} ${NGINX_CSP_REQUIRE_TRUSTED_TYPES_FOR:-}; \
script-src ${EMBEDDED_CSP_SCRIPT_SRC:-} ${NGINX_CSP_SCRIPT_SRC:-}; \
style-src ${EMBEDDED_CSP_STYLE_SRC:-} ${NGINX_CSP_STYLE_SRC:-}; \
trusted-types ${EMBEDDED_CSP_TRUSTED_TYPES:-} ${NGINX_CSP_TRUSTED_TYPES:-}; \
worker-src ${EMBEDDED_CSP_WORKER_SRC:-} ${NGINX_CSP_WORKER_SRC:-}; \
report-uri ${NGINX_CSP_REPORT_URI}; \
";
EOF
