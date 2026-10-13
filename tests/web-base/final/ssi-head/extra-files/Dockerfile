ARG BASE_IMAGE=web-base:test
FROM ${BASE_IMAGE}

# Only the SSI test fixture needs Node; production images remain unchanged.
# hadolint ignore=DL3018
RUN apk add --no-cache nodejs

COPY ssi-head-config.test.mjs /tests/ssi-head-config.test.mjs
COPY final/ssi-head/extra-files/server.mjs final/ssi-head/extra-files/check-ssi-head.test.mjs /tests/
COPY final/ssi-head/extra-files/s6-overlay/ /etc/s6-overlay/s6-rc.d/
