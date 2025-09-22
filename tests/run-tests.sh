#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

# Note: drop the "tag" from the name
IMAGE_NAME=$1
SUITE_NAME=${IMAGE_NAME%%:*}
IMAGE_TARGET=$2

run_test() {
  echo "Running ${1}…"
  pushd "$1" > /dev/null

  tempdir=$(mktemp -d /tmp/${SUITE_NAME}.XXXXXX)
  [ -d ../../common-files ] && cp -r ../../common-files/* "$tempdir"
  [ -d files ] && cp -rf files/* "$tempdir"

  ARGUMENTS=()
  if [ -f env.properties ]; then
    ARGUMENTS+=(--env-file "$PWD/env.properties")
  fi
  for file in $tempdir/*; do
    ARGUMENTS+=(--mount "type=bind,source=$file,target=/app/www/${file#$tempdir/}")
  done
  
  CUSTOM_ARGUMENTS=()
  CUSTOM_CMD=
  if [ -f run_overrides ]; then
    source run_overrides
  fi

  set +u
  dgoss_run \
    "${ARGUMENTS[@]}" \
    "${CUSTOM_ARGUMENTS[@]}" \
    $IMAGE_NAME \
    $CUSTOM_CMD
  set -u

  rm -rf "$tempdir"
  popd > /dev/null
}

dgoss_run() {
  # Remove some noise from dgoss output
  dgoss run "$@" \
    > >(grep -v -e '^Total Duration:' -e '^[[:space:]]*$') \
    2> >(grep -v -e '^INFO: ' >&2)
}

# Check we have a test suite
TEST_DIR="tests/$SUITE_NAME/$IMAGE_TARGET"
if [ ! -d "$TEST_DIR" ]; then
  echo "Error: missing test suite '$TEST_DIR'"
  exit 1
fi

for test in $TEST_DIR/*; do
  run_test "$test"
done
