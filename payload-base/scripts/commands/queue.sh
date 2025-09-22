#!/usr/bin/env sh
export IS_JOB=TRUE
exec node ./server.js "$@"
