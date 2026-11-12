#!/bin/bash
set -Eeuo pipefail
# Sourced by the official MySQL entrypoint only on a new data volume.
case "$MYSQL_DATABASE" in (*[!a-zA-Z0-9_]*|'') echo 'Invalid database name' >&2; exit 1;; esac
app_password="$(cat /run/secrets/db_password)"
migrator_password="$(cat /run/secrets/migrator_password)"
for value in "$app_password" "$migrator_password"; do
    case "$value" in (*[!a-zA-Z0-9_-]*|'') echo 'Use generated URL-safe database secrets' >&2; exit 1;; esac
done
MYSQL_PWD="$(cat /run/secrets/mysql_root_password)" mysql --protocol=socket --user=root --database="$MYSQL_DATABASE" <<EOSQL
CREATE USER 'sms_app'@'%' IDENTIFIED BY '${app_password}';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${MYSQL_DATABASE}\`.* TO 'sms_app'@'%';
CREATE USER 'sms_migrator'@'%' IDENTIFIED BY '${migrator_password}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO 'sms_migrator'@'%';
EOSQL
unset app_password migrator_password value
