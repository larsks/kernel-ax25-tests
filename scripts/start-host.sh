#!/bin/bash

: "${mac_prefix:=c0:ff:ee}"
: "${ax25_kernel:=/boot/vmlinuz}"
: "${ax25_initrd:=/boot/initrd}"

set -eu

hostname="$1"
ipaddr="$2"
netmask="${3:-255.255.255.0}"

if [[ -z $hostname ]] || [[ -z $ipaddr ]]; then
	echo "$0: usage: $0 <hostname> <address> <netmask>" >&2
	exit 2
fi

mkdir -p "/state/$hostname"
mkdir -p "/results/$hostname"

tapname=$(mktemp -u tapXXXXXX)
ip tuntap add mode tap "$tapname"
ip link set "$tapname" master br0 up

if ! [[ -f "/state/${hostname}.mac" ]]; then
	mac_trailer=$(head -c3 /dev/urandom | hexdump -e '3/1 "%02x:""\n"' | sed 's/:$//')
	mac_address="${mac_prefix}:${mac_trailer}"
	echo "$mac_address" >"/state/${hostname}/mac"
else
	mac_address=$(cat "/state/${hostname}/mac")
fi

env | grep -i ax25 >"/state/$hostname/ax25testconf"

echo "starting host $hostname" >&2
/scripts/runkernel.sh \
	-k "$ax25_kernel" \
	-i "$ax25_initrd" \
	-a "hostname=${hostname} ip=${ipaddr}:::${netmask}:${hostname}::off" \
	-b /scripts:scripts \
	-b /tests:tests \
	-b /state:state \
	-f opt/bashtty/ttyS2=on \
	-- \
	-nographic \
	-monitor "unix:/state/${hostname}/monitor,server,nowait" \
	-serial "file:/results/${hostname}/console.log" \
	-serial "file:/results/${hostname}/output.log" \
	-serial "unix:/state/${hostname}/shell,server,nowait" \
	-netdev tap,id=tap0,ifname="$tapname",script=no,downscript=no \
	-device "virtio-net-pci,netdev=tap0,mac=${mac_address}"
