
# syntax=docker/dockerfile:1.7

# Build Vite and its native dependencies in a glibc environment.
FROM node:22-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee AS build

WORKDIR /build

COPY frontend/package.json frontend/package-lock.json ./

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --prefer-offline --no-audit

COPY frontend/ ./

RUN npm run build

FROM nginxinc/nginx-unprivileged:1.28-alpine@sha256:7377697a821c131a924a7105fafbe7414db4e9fcc77a6f08f776f33f141ec3f8 AS runtime
USER root
# The stock image pins these modules to its nginx version; the app config loads none of them.
RUN apk del nginx-module-geoip nginx-module-image-filter nginx-module-njs nginx-module-xslt \
    && apk add --no-cache --upgrade 'nginx>=1.28.3-r8' libcrypto3 libssl3 brotli-libs
COPY frontend/nginx-main.conf /etc/nginx/nginx.conf

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /build/dist /usr/share/nginx/html

USER 101:101

EXPOSE 8080

HEALTHCHECK --interval=20s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
