#!/bin/bash

ip link add br0 type bridge
ip addr add 192.168.168.1/24 dev br0
ip link set br0 up

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

if ! [[ -f /tests/id_rsa ]]; then
	ssh-keygen -t rsa -b 4096 -N '' -f /tests/id_rsa
fi

webdir=$(mktemp -d /tmp/webXXXXXX)
echo OK >"$webdir/health"
darkhttpd "$webdir" --port 8080 --log /dev/null
