#!/usr/bin/env bash

set -eu

readonly IMAGE_NAME=$1
readonly IMAGE_TAG=$2
readonly IMAGE_TARGET=$3
readonly VERSIONS=$4
readonly DOCKERFILE="./$IMAGE_NAME/Dockerfile"

# Load versions into ENV
if [ -n "$VERSIONS" ]; then
  export $(echo "$VERSIONS" | xargs)
fi
if [ -z "$ALPINE_VERSION" ]; then
  echo "Require alpine version"
  exit 1
fi

# Calculate build args
BUILD_ARGS=()
while read item; do
  BUILD_ARGS+=(--build-arg "${item}")
done <<< "$(echo -e "$VERSIONS")"

# Calculate base
if grep -qE 'FROM common:.*-nginx AS' "$DOCKERFILE"; then
  readonly BASE_IMAGE_NAME="common:${ALPINE_VERSION}-nginx"
  readonly BASE_IMAGE_TARGET=nginx
elif grep -qE 'FROM common:.* AS' "$DOCKERFILE"; then
  readonly BASE_IMAGE_NAME="common:${ALPINE_VERSION}"
  readonly BASE_IMAGE_TARGET=base
fi

# Cleanup
(docker rmi "$BASE_IMAGE_NAME" || true) > /dev/null && \
  (docker rmi "$IMAGE_NAME:$IMAGE_TAG" || true) > /dev/null

# Build
if [[ -n "${BASE_IMAGE_TARGET:-}" ]]; then
  echo "Building base image $BASE_IMAGE_NAME"
  docker build -q \
    --tag "$BASE_IMAGE_NAME" \
    --target="$BASE_IMAGE_TARGET" \
    "${BUILD_ARGS[@]}" \
    ./common
fi
echo "Building image $IMAGE_NAME:$IMAGE_TAG"
docker build -q \
  --tag "$IMAGE_NAME:$IMAGE_TAG" \
  --target="$IMAGE_TARGET" \
  "${BUILD_ARGS[@]}" \
  "./$IMAGE_NAME"
