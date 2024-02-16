#
# --- Stage 1: Build ---
#

FROM node:lts as build

# Build import env tool
WORKDIR /app
RUN npm i @import-meta-env/cli && \
    npx pkg ./node_modules/@import-meta-env/cli/bin/import-meta-env.js \
      -t latest-alpine \
      -o import-meta-env

#
# --- Stage 2: Run ---
#

FROM nginx:stable-alpine as final

# # Copy configuration files
COPY ./config/nginx/ /etc/nginx/
COPY ./scripts/docker-entrypoint.sh /
COPY --from=build /app/import-meta-env /usr/bin/import-meta-env

# # Clean Up
WORKDIR /usr/share/nginx/html
RUN chown -R nobody:nobody /docker-entrypoint.sh

# # Start nginx by default
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["serve"]
