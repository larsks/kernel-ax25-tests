#!/bin/bash

set -e

ssh 192.168.168.10 /vol/scripts/setup-ax25.sh host0 \
	"'host1 host1 udp 10090'"
ssh 192.168.168.11 /vol/scripts/setup-ax25.sh host1 \
	"'host0 host0 udp 10090'"
