ARG BASE_IMAGE=web-base:test
FROM ${BASE_IMAGE}

# Only the SSI test fixture needs Node; production images remain unchanged.
# hadolint ignore=DL3018
RUN apk add --no-cache nodejs

COPY server.mjs /tests/
COPY s6-overlay/ /etc/s6-overlay/s6-rc.d/
