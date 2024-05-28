#!/bin/bash

: "${TEST_NET_CIDR:=192.168.53.0/24}"
: "${TEST_HOST_MEMORY:=512m}"
: "${TEST_MAC_PREFIX:=c0:ff:ee}"

export TEST_NET_CIDR TEST_HOST_MEMORY TEST_MAC_PREFIX

shopt -s nullglob

calculate_network_vars() {
	local NETWORK
	local NETMASK
	local PREFIX
	eval "$(ipcalc -pnm "$TEST_NET_CIDR")"

	TEST_NET_NETWORK=$NETWORK
	TEST_NET_NETMASK=$NETMASK
	TEST_NET_PREFIX=$PREFIX
	TEST_NET_GATEWAY=$(nth_host "$TEST_NET_NETWORK" 1)

	export TEST_NET_CIDR TEST_NET_NETWORK TEST_NET_PREFIX TEST_NET_NETMASK TEST_NET_GATEWAY
}

nth_host() {
	local network=$1
	local nth=$2

	network_prefix=${network%.*}
	network_suffix=${network##*.}
	echo "${network_prefix}.$((network_suffix + nth))"
}

on() {
	local target=$1
	shift
	# shellcheck disable=SC2154
	ssh -i "$ssh_private_key" "$target" "${@:-bash}"
}

#-a "hostname=${hostname} ip=${ipaddr}::${gateway}:${netmask}:${hostname}::off" \
start_one_host() {
	local hostname=$1
	local ipaddr=$2

	echo "start host $hostname"
	mkdir -p "$tmpdir/$hostname"

	iparg="ip=$ipaddr::$TEST_NET_GATEWAY:$TEST_NET_NETMASK:$hostname::off"

	ip tuntap add mode tap "$hostname"
	ip link set "$hostname" master br0 up

	mac_trailer=$(head -c3 /dev/urandom | hexdump -e '3/1 "%02x:""\n"' | sed 's/:$//')
	mac_address="${TEST_MAC_PREFIX}:${mac_trailer}"
	echo "$mac_address" >"$tmpdir/${hostname}/mac"

	qemu-system-x86_64 -enable-kvm -m "$TEST_HOST_MEMORY" \
		-kernel "/boot/vmlinuz" \
		-initrd "/boot/initrd" \
		-append "hostname=${hostname} console=tty0 console=ttyS0,115200 no_timer_check net.ifnames=0 rw $iparg" \
		-nographic \
		-monitor "unix:$tmpdir/$hostname/monitor,server,nowait" \
		-serial "file:$tmpdir/$hostname/console" \
		-serial "unix:$tmpdir/$hostname/shell,server,nowait" \
		-fw_cfg name=opt/ttytab/ttyS1,string=/bin/bash \
		-pidfile "$tmpdir/$hostname/pid" \
		-netdev "tap,id=tap0,ifname=$hostname,script=no,downscript=no" \
		-device "virtio-net-pci,netdev=tap0,mac=${mac_address}" \
		$(qemu_bind_path "$tmpdir" state) \
		$(qemu_bind_path "/scripts" scripts) \
		$(qemu_bind_path "/results" results) \
		&

	while ! ssh -i "$ssh_private_key" "$hostname" true >/dev/null 2>&1; do
		echo "waiting for $hostname"
		sleep 1
	done
}

start_hosts() {
	local num_hosts="$1"
	local hostaddrs=()
	local hostnames=()

	echo "$num_hosts" >"$tmpdir/num_hosts"

	for ((i = 0; i < num_hosts; i++)); do
		hostname="host${i}"
		ipaddr=$(nth_host "$TEST_NET_NETWORK" $((10 + i)))
		hostaddrs+=("$ipaddr")
		hostnames+=("$hostname")
		echo "$ipaddr $hostname" >>"$tmpdir/hosts"
	done

	cat "$tmpdir/hosts" >>/etc/hosts

	for ((i = 0; i < num_hosts; i++)); do
		start_one_host "${hostnames[$i]}" "${hostaddrs[$i]}"
	done
}

stop_all_hosts() {
	local num_hosts="$(cat "$tmpdir/num_hosts")"

	for ((i = 0; i < num_hosts; i++)); do
		stop_one_host "$i"
	done
}

stop_one_host() {
	local host_index
	local hostname
	host_index=$1
	hostname="host${host_index}"

	if [[ -S $tmpdir/$hostname/monitor ]]; then
		echo quit | nc -UN "$tmpdir/$hostname/monitor"
	fi

	if [[ -f $tmpdir/$hostname/pid ]]; then
		pid="$(cat "$tmpdir/$hostname/pid")"
		while kill -0 "$pid"; do
			sleep 0.5
		done
	fi

	ip link del "$hostname" || :

	cleanhosts=$(mktemp "$tmpdir/hostsXXXXXX")
	sed "/$hostname /d" /etc/hosts >"$cleanhosts"
	cat "$cleanhosts" >/etc/hosts
	rm -f "$cleanhosts"
}

setup_test_network() {
	ip link add br0 type bridge
	ip addr add "$TEST_NET_GATEWAY/$TEST_NET_PREFIX" dev br0
	ip link set br0 up

	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

teardown_test_network() {
	ip link del br0
	iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
}

setup_ssh_credentials() {
	if ! [[ -f $tmpdir/id_rsa ]]; then
		ssh-keygen -qN '' -f "$tmpdir/id_rsa"
	fi
	ssh_private_key="$tmpdir/id_rsa"
}

qemu_bind_path() {
	local path=$1
	local tag=$2
	echo \
		-fsdev "local,path=$path,id=$tag,security_model=none" \
		-device "virtio-9p-pci,id=$tag,fsdev=$tag,mount_tag=$tag"
}
