
# syntax=docker/dockerfile:1.7

FROM maven:3.9.9-eclipse-temurin-21@sha256:3a4ab3276a087bf276f79cae96b1af04f53731bec53fb2e651aca79e4b10211e AS build

WORKDIR /build

COPY infrastructure/migration/pom.xml ./pom.xml

RUN --mount=type=cache,target=/root/.m2,sharing=locked \
    mvn -B -ntp dependency:go-offline

COPY infrastructure/migration/src ./src

RUN --mount=type=cache,target=/root/.m2,sharing=locked \
    mvn -B -ntp -DskipTests package

FROM eclipse-temurin:21-jre-jammy@sha256:dff6eb46527bd293a3c06bbbe9e64e8c9f91f01905b5abbdad31761c03059d2c AS runtime

RUN groupadd --gid 10001 sms \
    && useradd --uid 10001 --gid sms --create-home sms

WORKDIR /migrations

COPY --from=build --chown=sms:sms \
    /build/target/schema-migration-1.0.0.jar /app/migration.jar

COPY --chown=sms:sms db/migration/core /migrations/core

COPY --chown=sms:sms db/migration/demo /migrations/demo

USER 10001:10001

ENTRYPOINT ["java", "-jar", "/app/migration.jar"]
