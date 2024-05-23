#!/bin/bash

bindpath() {
	cat <<EOF
-fsdev local,path=$1,id=$2,security_model=none -device virtio-9p-pci,id=$2,fsdev=$2,mount_tag=$2
EOF
}

set -eu

: "${ax25_kernel:=/boot/vmlinuz}"
: "${ax25_initrd:=/boot/initrd}"

consoleport="$1"
hostname="$2"
ipaddr="$3"

if [[ -z $consoleport ]] || [[ -z $hostname ]] || [[ -z $ipaddr ]]; then
	echo "$0: usage: $0 <consoleport> <hostname> <address>" >&2
	exit 2
fi

tapname=$(mktemp -u tapXXXXXX)
ip tuntap add mode tap "$tapname"
ip link set "$tapname" master br0 up

mac_trailer=$(head -c3 /dev/urandom | hexdump -e '3/1 "%02x:""\n"' | sed 's/:$//')

qemu-system-x86_64 \
	-enable-kvm -m 1g \
	-kernel "$ax25_kernel" \
	-initrd "$ax25_initrd" \
	-append "hostname=${hostname} ip=${ipaddr}:::255.255.255.0:${hostname}::off console=ttyS0,115200 no_timer_check net.ifnames=0 rw${KERNEL_ARGS:+ ${KERNEL_ARGS}}" \
	-nographic \
	-serial "file:/results/${hostname}-console.log" \
	-serial "file:/results/${hostname}-output.log" \
	-serial "unix:/consoles/${hostname},server,nowait" \
	-netdev tap,id=tap0,ifname="$tapname",script=no,downscript=no \
	-device "virtio-net-pci,netdev=tap0,mac=c0:ff:ee:${mac_trailer}" \
	$(bindpath /scripts scripts) \
	$(bindpath /tests tests)
