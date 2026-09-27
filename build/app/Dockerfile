# Base image: ubuntu:24.04 (tag `latest`) or debian:trixie-slim (tag `debian`)
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    systemd systemd-sysv wget curl libatomic1 ca-certificates \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/* \
    && rm -f /lib/systemd/system/plymouth* \
    && rm -f /lib/systemd/system/systemd-update-utmp* \
    && apt-get clean

# Expected EarnApp version (empty: whatever BrightData currently serves). Also part of the layer
# cache key, so a new release is never served from cache.
ARG EARNAPP_VERSION=
RUN --mount=type=bind,source=common/fetch-earnapp.sh,target=/fetch-earnapp.sh \
    bash /fetch-earnapp.sh "$EARNAPP_VERSION"

COPY --chmod=755 common/install.sh /usr/local/bin/earnapp-setup
COPY --chmod=755 common/myip.sh /usr/bin/myip
COPY common/installer.service /etc/systemd/system/installer.service
RUN systemctl enable installer.service

VOLUME [ "/etc/earnapp" ]

CMD ["/sbin/init"]
