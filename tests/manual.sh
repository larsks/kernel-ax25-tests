#!/bin/bash

. tests/testlib.sh

tmpdir=$(mktemp -d /tmp/manualXXXXXX)

calculate_network_vars
setup_test_network
setup_ssh_credentials
start_hosts 2

exec /bin/bash
