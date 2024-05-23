FROM docker.io/alpine:latest

RUN apk update && \
  apk add \
    bash \
    ax25-tools \
    ax25-apps \
    iproute2 \
    net-tools \
    vim \
    procps \
    curl \
    tmux \
    openssh \
    openrc \
    socat \
    netcat-openbsd

RUN bash <<EOF
rc-update add sshd default
rc-update add localmount
EOF

COPY etc/ /etc/
COPY init /init
