FROM ubuntu:24.04

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget dos2unix libatomic1 \
    && rm -Rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app

COPY common/setup.sh src/setup.sh
COPY lite/src/install.sh src/install.sh
RUN dos2unix src/* \
    && cp /app/src/install.sh /usr/bin/install \
    && chmod a+x /usr/bin/install

RUN bash /app/src/setup.sh && rm -r /app/src

VOLUME [ "/etc/earnapp" ]

CMD ["install"]

HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=2 CMD cat /etc/earnapp/status | grep enabled && exit 0 || exit 1
