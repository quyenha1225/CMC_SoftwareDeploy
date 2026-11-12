#!/bin/sh
set -eu
export FLYWAY_PASSWORD="$(cat /run/secrets/migrator_password)"
export FLYWAY_LOCATIONS=filesystem:/flyway/sql/core
if [ "${SMS_SEED_DEMO:-false}" = true ]; then
    if [ "${SMS_ENVIRONMENT:-local}" = production ]; then echo 'Demo seed forbidden in production' >&2; exit 1; fi
    export FLYWAY_LOCATIONS=filesystem:/flyway/sql/core,filesystem:/flyway/sql/demo
fi
exec /flyway/flyway "$@"
