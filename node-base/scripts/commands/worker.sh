#!/usr/bin/env sh
safe_exec node ./dist/src/entrypoints/worker.js "$@"
