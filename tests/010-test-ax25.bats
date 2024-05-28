#!/bin/bash

. tests/testlib.sh

setup_file() {
	calculate_network_vars
	setup_test_network
}

teardown_file() {
	teardown_test_network
}

setup() {
	tmpdir=$(mktemp -d /tmp/testXXXXXX)
	setup_ssh_credentials
	start_hosts 2
}

teardown() {
	stop_all_hosts
	logs=$(mktemp -d /results/logsXXXXXX)
	tar -C "$tmpdir" -cf- . | tar -C "$logs" -xf-
	rm -rf "$tmpdir"
}

@test "we can create an ax25 connection" {
	bats_require_minimum_version 1.5.0
	on host0 <<EOF
/vol/scripts/setup-ax25.sh host0 'host1 host1 udp 10090'
EOF
	on host1 <<EOF
/vol/scripts/setup-ax25.sh host1 'host0 host0 udp 10090'
cat > /etc/ax25/ax25d.conf <<END_AX25D
[udp0]
default  * * * * * *  - root  /bin/echo echo AX25 TEST OUTPUT
END_AX25D
EOF
	on host0 <<EOF >"$tmpdir/stdout" 2>"$tmpdir/stderr"
call -SRr udp0 host1
EOF
	run grep 'AX25 TEST OUTPUT' "$tmpdir/stdout"
	run ! grep -qE -- 'waiting for.*to become free|--[ cut here ]--' "$tmpdir/*/console"
}

@test "we can create many ax25 connections" {
	bats_require_minimum_version 1.5.0
	on host0 <<EOF
/vol/scripts/setup-ax25.sh host0 'host1 host1 udp 10090'
EOF
	on host1 <<EOF
/vol/scripts/setup-ax25.sh host1 'host0 host0 udp 10090'
cat > /etc/ax25/ax25d.conf <<END_AX25D
[udp0]
default  * * * * * *  - root  /bin/echo echo AX25 TEST OUTPUT
END_AX25D
nohup listen -a > "/vol/state/axlisten.out" 2>"/vol/state/axlisten.err"
EOF
	for i in {1..30}; do
		echo "connection attemp $i"
		on host0 <<EOF >"$tmpdir/stdout" 2>"$tmpdir/stderr"
call -SRr udp0 host1
EOF
		run grep 'AX25 TEST OUTPUT' "$tmpdir/stdout"
		run ! grep -qE -- 'waiting for.*to become free|--[ cut here ]--' "$tmpdir/*/console"

		# need to wait for connection to expire
		sleep 5
	done
}
