
# syntax=docker/dockerfile:1.7

FROM maven:3.9.9-eclipse-temurin-21@sha256:3a4ab3276a087bf276f79cae96b1af04f53731bec53fb2e651aca79e4b10211e AS build

WORKDIR /build

COPY backend/pom.xml ./pom.xml

RUN --mount=type=cache,target=/root/.m2,sharing=locked \
    mvn -B -ntp dependency:go-offline

COPY backend/src ./src

RUN --mount=type=cache,target=/root/.m2,sharing=locked \
    mvn -B -ntp -DskipTests package

FROM eclipse-temurin:21-jre-jammy@sha256:dff6eb46527bd293a3c06bbbe9e64e8c9f91f01905b5abbdad31761c03059d2c AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 sms \
    && useradd --uid 10001 --gid sms --create-home sms

WORKDIR /app

COPY --from=build --chown=sms:sms \
    /build/target/backend-0.0.1-SNAPSHOT.jar /app/backend.jar

RUN mkdir -p /app/private-files \
    && chown sms:sms /app/private-files

USER 10001:10001

EXPOSE 8081 9092

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70.0 -Duser.timezone=Asia/Ho_Chi_Minh"

HEALTHCHECK --interval=20s --timeout=5s --start-period=90s --retries=5 \
    CMD curl --fail --silent http://127.0.0.1:9092/actuator/health/readiness >/dev/null || exit 1

ENTRYPOINT ["java", "-jar", "/app/backend.jar"]
