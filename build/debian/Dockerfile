FROM debian:bookworm-slim

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    software-properties-common systemd systemd-cron \
    wget curl dos2unix libatomic1 ca-certificates \
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

RUN curl -sfL https://brightdata.com/static/earnapp/install.sh | bash -s install

WORKDIR /app

COPY common/install.sh /app/src/install.sh
COPY common/installer.service /app/src/installer.service
RUN dos2unix /app/src/* \
    && cp /app/src/install.sh /usr/bin/install \
    && cp /app/src/installer.service /etc/systemd/system/installer.service \
    && systemctl enable installer.service \
    && rm -r /app/src

VOLUME [ "/etc/earnapp" ]
VOLUME ["/sys/fs/cgroup"]

CMD ["/sbin/init"]
