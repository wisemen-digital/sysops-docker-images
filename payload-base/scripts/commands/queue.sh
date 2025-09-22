#!/usr/bin/env sh
export IS_JOB=TRUE
safe_exec node ./server.js "$@"
