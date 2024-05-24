#!/bin/bash

rm -rf /state/*

ip link add br0 type bridge
ip addr add 192.168.168.1/24 dev br0
ip link set br0 up

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

rm -f /root/.ssh/id_rsa
ssh-keygen -t rsa -b 4096 -N '' -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /state/

webdir=$(mktemp -d /tmp/webXXXXXX)
echo OK >"$webdir/health"
darkhttpd "$webdir" --port 8080 --log /dev/null
