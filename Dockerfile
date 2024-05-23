FROM docker.io/alpine:latest

RUN apk add \
  qemu-system-x86_64 \
  darkhttpd \
  curl \
  iproute2 \
  bash \
  socat \
  netcat-openbsd
