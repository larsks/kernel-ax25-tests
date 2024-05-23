FROM docker.io/alpine:latest

RUN apk add \
  bash \
  curl \
  darkhttpd \
  iproute2 \
  iptables \
  netcat-openbsd \
  openssh \
  qemu-system-x86_64 \
  socat

RUN bash <<EOF
mkdir -m 700 -p /root/.ssh
cat > /root/.ssh/config <<END_CONFIG
Host *
  StrictHostkeyChecking no
  UserKnownHostsFile /dev/null
END_CONFIG
EOF
