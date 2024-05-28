#!/bin/bash
#
# The tests in this file test the test infratsructure: they ensure networking
# is configured correctly and that we are successfully exposing host
# directories into the virtual machines.

. tests/testlib.sh

setup_file() {
	tmpdir=$(mktemp -d /tmp/testXXXXXX)

	calculate_network_vars
	setup_test_network
	setup_ssh_credentials
	start_hosts 2

	# Variables defined in setup_file must be exported to be visible
	# in subsequent tests.
	export tmpdir
	export ssh_private_key
}

teardown_file() {
	stop_all_hosts
	teardown_test_network
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
