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
    netcat-openbsd \
    python3

RUN sed -i '/^#\?PermitRootLogin/ s/.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

COPY etc/ /etc/
COPY init /init

RUN bash <<EOF
rc-update add sshd default
rc-update add install-ssh-keys default
EOF
