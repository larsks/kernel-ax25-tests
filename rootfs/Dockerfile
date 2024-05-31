FROM docker.io/alpine:latest AS builder

RUN apk add \
  alpine-sdk \
  git \
  autoconf \
  automake \
  libtool \
  zlib-dev \
  linux-headers \
  ncurses-dev \
  musl-dev

RUN mkdir /usr/include/protocols

WORKDIR /build
COPY build-ax25.sh ./
COPY alpine.patch ./
RUN sh build-ax25.sh

COPY helloax25.c ./
RUN gcc -o helloax25 helloax25.c -lax25 && install -m 755 helloax25 /usr/sbin

FROM docker.io/alpine:latest

RUN apk update && \
  apk add \
    bash \
    iproute2 \
    net-tools \
    procps \
    curl \
    openssh \
    openrc \
    socat \
    netcat-openbsd \
    util-linux \
    tcpdump \
    strace

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

COPY --from=builder /usr/lib/libax25* /usr/lib/
COPY --from=builder /opt/ax25/sbin/* /usr/sbin/
COPY --from=builder /opt/ax25/bin/* /usr/bin/
COPY --from=builder /usr/sbin/helloax25 /usr/sbin/
RUN mkdir /etc/ax25
