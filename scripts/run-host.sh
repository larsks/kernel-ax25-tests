#!/bin/bash

: "${mac_prefix:=c0:ff:ee}"

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

if ! [[ -f "/state/${hostname}.mac" ]]; then
	mac_trailer=$(head -c3 /dev/urandom | hexdump -e '3/1 "%02x:""\n"' | sed 's/:$//')
	mac_address="${mac_prefix}:${mac_trailer}"
	echo "$mac_address" >"/state/${hostname}.mac"
else
	mac_address=$(cat "/state/${hostname}.mac")
fi

env | grep -i ax25 >/tmp/ax25testconf

echo "starting host $hostname" >&2
qemu-system-x86_64 \
	-enable-kvm -m 1g \
	-kernel "$ax25_kernel" \
	-initrd "$ax25_initrd" \
	-append "hostname=${hostname} ip=${ipaddr}::192.168.168.1:255.255.255.0:${hostname}::off console=ttyS0,115200 no_timer_check net.ifnames=0 rw${KERNEL_ARGS:+ ${KERNEL_ARGS}}" \
	-nographic \
	-monitor "unix:/state/${hostname}-monitor,server,nowait" \
	-serial "file:/results/${hostname}-console.log" \
	-serial "file:/results/${hostname}-output.log" \
	-serial "unix:/state/${hostname},server,nowait" \
	-netdev tap,id=tap0,ifname="$tapname",script=no,downscript=no \
	-device "virtio-net-pci,netdev=tap0,mac=${mac_address}" \
	-fw_cfg "opt/ax25/testconf,file=/tmp/ax25testconf" \
	$(bindpath /scripts scripts) \
	$(bindpath /tests tests) \
	$(bindpath /state state)
