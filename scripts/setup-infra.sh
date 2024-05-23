#!/bin/bash

ip link add br0 type bridge
ip link set br0 up

ssh-keygen -t rsa -b 4096 -N '' -f /tests/id_rsa

webdir=$(mktemp -d /tmp/webXXXXXX)
echo OK >"$webdir/health"
darkhttpd "$webdir" --port 8080 --log /dev/null
