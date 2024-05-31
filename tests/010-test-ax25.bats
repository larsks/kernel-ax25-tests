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
	chmod 755 "$tmpdir"
	setup_ssh_credentials
	start_hosts 2
}

teardown() {
	stop_all_hosts
	logs=$(mktemp -d /results/logsXXXXXX)
	tar -C "$tmpdir" -cf- . | tar -C "$logs" -xf-
	rm -rf "$tmpdir"
}

@test "we can create a single ax25 connection" {
	bats_require_minimum_version 1.5.0
	on host0 <<EOF
/vol/scripts/setup-ax25.sh host0 'host1 host1 udp 10090'
EOF
	on host1 <<EOF
/vol/scripts/setup-ax25.sh host1 'host0 host0 udp 10090'
cat >> /etc/inittab <<END_INITTAB
::respawn:/usr/sbin/helloax25 udp0
END_INITTAB
kill -HUP 1
sleep 1
EOF
	on host0 <<EOF >"$tmpdir/stdout" 2>"$tmpdir/stderr"
call -SRr udp0 host1
EOF
	run -0 grep 'HELLO AX.25 CALLER' "$tmpdir/stdout"
	run -1 grep -qE -- 'waiting for.*to become free|--[ cut here ]--' "$tmpdir"/*/console
}

@test "we can create multiple ax25 connections" {
	bats_require_minimum_version 1.5.0
	on host0 <<EOF
/vol/scripts/setup-ax25.sh host0 'host1 host1 udp 10090'
EOF
	on host1 <<EOF
/vol/scripts/setup-ax25.sh host1 'host0 host0 udp 10090'
cat >> /etc/inittab <<END_INITTAB
::respawn:/usr/sbin/helloax25 udp0
END_INITTAB
kill -HUP 1
sleep 1
EOF
	on host0 <<EOF >"$tmpdir/stdout" 2>"$tmpdir/stderr"
for i in {1..20}; do
call -SRr udp0 host1
sleep 8
done
EOF
	count=$(grep -c 'HELLO AX.25 CALLER' "$tmpdir/stdout")
	if ! [[ $count = 20 ]]; then
		echo "expected 20, got $count" >&2
		return 1
	fi
	run -1 grep -qE -- 'waiting for.*to become free|--[ cut here ]--' "$tmpdir"/*/console
}
