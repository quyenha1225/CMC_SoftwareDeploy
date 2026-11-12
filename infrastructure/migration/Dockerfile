# syntax=docker/dockerfile:1.7
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY infrastructure/migration/pom.xml ./pom.xml
COPY infrastructure/migration/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp -DskipTests package
FROM eclipse-temurin:21-jre-jammy AS runtime
RUN groupadd --gid 10001 sms && useradd --uid 10001 --gid sms --create-home sms
WORKDIR /migrations
COPY --from=build --chown=sms:sms /build/target/schema-migration-1.0.0.jar /app/migration.jar
COPY db/migration/core /migrations/core
COPY db/migration/demo /migrations/demo
USER 10001:10001
ENTRYPOINT ["java","-jar","/app/migration.jar"]
