#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME=$1
IMAGE_TARGET=$2
VERSIONS=$3
DOCKERFILE="./$IMAGE_NAME/Dockerfile"

# Calculate build args
BUILD_ARGS=()
while read item; do
  BUILD_ARGS+=(--build-arg "${item}")
done <<< "$(echo -e "$VERSIONS")"

# Cleanup
(docker rmi "$IMAGE_NAME" || true) > /dev/null

# Build
echo "Building image $IMAGE_NAME"
docker build -q \
  --tag "$IMAGE_NAME" \
  --target="$IMAGE_TARGET" \
  "${BUILD_ARGS[@]}" \
  "./$IMAGE_NAME"
