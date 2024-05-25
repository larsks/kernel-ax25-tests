#!/bin/bash

if [[ -z "$ax25_num_hosts" ]]; then
	echo "ERROR: missing ax25_num_hosts environment variable" >&2
	exit 1
fi

for ((i = 0; i < ax25_num_hosts; i++)); do
	echo "[$i] host${i}"
	echo system_reset | nc -NU /state/host${i}/monitor >/dev/null
done
