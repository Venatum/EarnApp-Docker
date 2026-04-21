FROM ubuntu:24.04

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates libatomic1 openssl \
    && rm -Rf /var/lib/apt/lists/* \
    && apt-get clean

RUN curl -sfL https://brightdata.com/static/earnapp/install.sh -o /tmp/install.sh \
    && bash /tmp/install.sh -y || true \
    && rm -f /tmp/install.sh \
    && test -x /usr/bin/earnapp

COPY lite/src/entrypoint.sh /usr/bin/entrypoint
RUN chmod a+x /usr/bin/entrypoint

VOLUME [ "/etc/earnapp" ]

ENTRYPOINT ["entrypoint"]

HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=2 CMD cat /etc/earnapp/status | grep enabled && exit 0 || exit 1
