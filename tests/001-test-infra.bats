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
	rm -rf "$tmpdir"
}

@test "we can ssh to test hosts" {
	for host in host0 host1; do
		on $host date
	done
}

@test "we can connect between hosts" {
	on host0 ping -c1 host1
	on host1 ping -c1 host0
}

@test "9p volumes exist" {
	for host in host0 host1; do
		on $host ls -ld /vol/scripts
		on $host ls -ld /vol/state
		on $host ls -l /vol/scripts/setup-ax25.sh
	done
}
