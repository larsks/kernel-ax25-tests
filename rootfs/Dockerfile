FROM docker.io/alpine:latest

RUN apk update && \
  apk add \
    bash \
    ax25-tools \
    ax25-apps \
    iproute2 \
    net-tools \
    procps \
    curl \
    openssh \
    openrc \
    socat \
    netcat-openbsd \
    python3 \
    util-linux

RUN sed -i '/^#\?PermitRootLogin/ s/.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

COPY etc/ /etc/
COPY init /init

RUN bash <<EOF
rc-update add sshd default
rc-update add install-ssh-keys default
rc-update add mount9p default
rc-update add extrattys default
rc-update add addhosts default
rc-update add syslogd default
EOF
