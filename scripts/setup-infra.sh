#!/bin/bash

: "${ax25_num_hosts:=1}"

rm -rf /state/*

ip link add br0 type bridge
ip addr add 192.168.168.1/24 dev br0
ip link set br0 up

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

rm -f /root/.ssh/id_rsa
ssh-keygen -t rsa -b 4096 -N '' -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /state/

rm -f /state/hosts
for ((i = 0; i < ax25_num_hosts; i++)); do
	hostname=host$i
	addr=192.168.168.$((10 + i))
	echo "$addr $hostname" >>/state/hosts
done

cat /state/hosts >>/etc/hosts

echo "starting $ax25_num_hosts hosts..."
for ((i = 0; i < ax25_num_hosts; i++)); do
	hostname=host$i
	addr=192.168.168.$((10 + i))
	echo "[$i] $hostname"

	/scripts/start-host.sh "$hostname" "$addr" &
done

exec sleep inf
