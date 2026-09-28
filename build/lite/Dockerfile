FROM ubuntu:24.04

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates libatomic1 openssl \
    && rm -Rf /var/lib/apt/lists/* \
    && apt-get clean

# Expected EarnApp version (empty: whatever BrightData currently serves). Also part of the layer
# cache key, so a new release is never served from cache.
ARG EARNAPP_VERSION=
RUN --mount=type=bind,source=common/fetch-earnapp.sh,target=/fetch-earnapp.sh \
    bash /fetch-earnapp.sh "$EARNAPP_VERSION"

COPY --chmod=755 lite/src/entrypoint.sh /usr/bin/entrypoint

VOLUME [ "/etc/earnapp" ]

ENTRYPOINT ["entrypoint"]

HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=2 CMD ["grep", "-q", "enabled", "/etc/earnapp/status"]
