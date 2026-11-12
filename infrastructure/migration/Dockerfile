FROM redgate/flyway:11.8.2
COPY db/migration/core /flyway/sql/core
COPY db/migration/demo /flyway/sql/demo
COPY infrastructure/migration/entrypoint.sh /flyway/entrypoint-sms.sh
ENTRYPOINT ["/bin/sh","/flyway/entrypoint-sms.sh"]
