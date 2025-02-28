#!/usr/bin/env sh

set -euo pipefail

# Configure nginx security based on ENV vars.
#
# Inputs (aside from all the individual CSP settings):
# - NGINX_CSP_MODE: defaults to 'enforce'
# - NGINX_CSP_REPORT_URI: defaults to ''
# - NGINX_FRAME_OPTIONS: defaults to 'deny', note that setting to `disable` removes the header completely.

# Set defaults
NGINX_CONFIG_FILE='/etc/nginx/snippets/vars/csp-and-robots.conf'
NGINX_CSP_ITEMS='child-src connect-src font-src form-action frame-ancestors frame-src img-src manifest-src media-src object-src require-trusted-types-for script-src style-src trusted-types worker-src'
NGINX_CSP_MODE="${NGINX_CSP_MODE:-enforce}"
NGINX_CSP_REPORT_URI="${NGINX_CSP_REPORT_URI:-}"
NGINX_FRAME_OPTIONS="${NGINX_FRAME_OPTIONS:-deny}"

# Validate input
if [ "${NGINX_CSP_MODE}" = 'enforce' ]; then
  NGINX_CSP_VAR_NAME='content_security_policy'
elif [ "${NGINX_CSP_MODE}" = 'report-only' ]; then
  NGINX_CSP_VAR_NAME='content_security_policy_report_only'
else
  echo "Nginx: invalid CSP mode ${NGINX_CSP_MODE}"
  exit 1
fi

# Check nginx structure
if [ ! -f "${NGINX_CONFIG_FILE}" ]; then
  echo "Nginx: var-csp-and-robots.conf file is missing, skipping configuring it…"
  exit 0
fi

# Helper to print nginx constant
nginx_var_definition() {
    cat <<EOF
map "" \$$1 {
  default "$2";
}
EOF
}

# nginx frame options header
if [ "${NGINX_FRAME_OPTIONS}" = 'disable' ]; then
  echo "Nginx: configuring frame options as disabled…"
  nginx_var_definition 'x_frame_options' '' > "${NGINX_CONFIG_FILE}"
else
  echo "Nginx: configuring frame options with '${NGINX_FRAME_OPTIONS}'…"
  nginx_var_definition 'x_frame_options' "${NGINX_FRAME_OPTIONS}" > "${NGINX_CONFIG_FILE}"
fi

# Helper to lookup & output CSP items
csp_item() {
  item="$1"

  # Lookup values if needed, checking `NGINX_CSP_…`
  if [ -n "${2:-}" ]; then
    value="$2"
  else
    uc_item=$(echo "$item" | tr '[:lower:]-' '[:upper:]_')
    value=$(printenv "NGINX_CSP_${uc_item}" || true)
  fi

  # Only output if we have a value
  if [ -n "$value" ]; then
    printf " %s %s;" "$item" "$value"
  fi
}

# Helper to print a full CSP definition
nginx_csp_definition() {
  name="$1"

  if [ "$name" = "$NGINX_CSP_VAR_NAME" ]; then
    nginx_var_definition "$name" "$(
      printf "default-src 'self';"
      for item in $NGINX_CSP_ITEMS; do
        csp_item "$item"
      done
      csp_item 'report-uri' "$NGINX_CSP_REPORT_URI"
    )"
  else
    nginx_var_definition "$name" ''
  fi
}

# nginx content policy
echo "Nginx: configuring content security policy…"
nginx_csp_definition content_security_policy >> "${NGINX_CONFIG_FILE}"
nginx_csp_definition content_security_policy_report_only >> "${NGINX_CONFIG_FILE}"
