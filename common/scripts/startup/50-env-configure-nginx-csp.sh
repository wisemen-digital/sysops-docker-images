#!/usr/bin/env sh

set -eu

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
# - NGINX_CSP_MODE: defaults to 'report-only'
# - NGINX_CSP_REPORT_URI: defaults to ''
# - NGINX_FRAME_OPTIONS: defaults to 'deny', note that setting to `disable` removes the header completely.

# Set defaults
readonly NGINX_CONFIG_FILE='/etc/nginx/snippets/vars/csp-and-robots.conf'
readonly NGINX_CSP_ITEMS='child-src connect-src font-src form-action frame-ancestors frame-src img-src manifest-src media-src object-src require-trusted-types-for script-src style-src trusted-types worker-src'
readonly NGINX_CSP_MODE="${NGINX_CSP_MODE:-report-only}"
readonly NGINX_CSP_REPORT_URI="${NGINX_CSP_REPORT_URI:-}"
readonly NGINX_FRAME_OPTIONS="${NGINX_FRAME_OPTIONS:-deny}"

# Validate input
if [ "${NGINX_CSP_MODE}" = 'enforce' ]; then
  readonly NGINX_CSP_VAR_NAME='content_security_policy'
elif [ "${NGINX_CSP_MODE}" = 'report-only' ]; then
  readonly NGINX_CSP_VAR_NAME='content_security_policy_report_only'
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

# Load embedded CSP values from file (if it exists)
EMBEDDED_CSP_PATH=/etc/csp-generator/default
if [ -f "${EMBEDDED_CSP_PATH}" ]; then
  echo "Nginx: found CSP defaults at '$EMBEDDED_CSP_PATH', processing…"
  PROCESSED_CSP_PATH=$(mktemp)
  sed 's/[^=]\+=/export EMBEDDED_CSP_&/' "${EMBEDDED_CSP_PATH}" > "${PROCESSED_CSP_PATH}"
  . "${PROCESSED_CSP_PATH}"
  rm "${PROCESSED_CSP_PATH}"
fi

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

  # Lookup values if needed, checking `EMBEDDED_CSP_…` and `NGINX_CSP_…`
  if [ -n "${2:-}" ]; then
    value="$2"
  else
    uc_item=$(echo "$item" | tr '[:lower:]-' '[:upper:]_')
    embedded_val=$( (printenv "EMBEDDED_CSP_${uc_item}" || true) | sed 's/^"//; s/"$//')
    nginx_val=$( (printenv "NGINX_CSP_${uc_item}" || true) | sed 's/^"//; s/"$//')
    value="${embedded_val}${embedded_val:+${nginx_val:+ }}${nginx_val}"
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
