FROM ubuntu:24.04

LABEL maintainer="Venatum"
LABEL org.opencontainers.image.authors="Venatum"

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    software-properties-common systemd systemd-cron \
    wget dos2unix libatomic1 \
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

WORKDIR /app

COPY common/ src/
RUN dos2unix src/* \
    && cp /app/src/install.sh /usr/bin/install \
    && chmod a+x /usr/bin/install \
    && cp /app/src/myip.sh /usr/bin/myip \
    && chmod a+x /usr/bin/myip

RUN cp /app/src/installer.service /etc/systemd/system/installer.service \
    && systemctl enable installer.service

RUN bash /app/src/setup.sh && rm -r /app/src

VOLUME [ "/etc/earnapp" ]
VOLUME ["/sys/fs/cgroup"]

CMD ["/sbin/init"]
