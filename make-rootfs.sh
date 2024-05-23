#!/bin/bash

docker build --label ax25 -t ax25-rootfs rootfs

fakeroot bash <<'EOF'
rootfs=$(mktemp -d rootfsXXXXXX)
trap 'rm -rf "$rootfs"' exit

docker container create --label ax25 --name "ax25-rootfs-exporter" ax25-rootfs
docker container export "ax25-rootfs-exporter" | tar -C "$rootfs" -xf-
docker container rm -f "ax25-rootfs-exporter"
tar -C "./rootfs.template" -cf- . | tar -C "$rootfs" -xf-

mkdir -p boot
(
cd "$rootfs"
find . -print0 | cpio -0 -o -H newc
) | gzip > boot/initrd
EOF
