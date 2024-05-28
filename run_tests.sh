#!/bin/sh

docker build -t ax25_tests .

docker run --rm --name "$(mktemp -u ax25_tests_XXXXXX)" \
	--label ax25tests \
	--cap-add NET_ADMIN \
	--device /dev/net/tun \
	--device /dev/kvm \
	-v "$PWD/boot:/boot" \
	-v "$PWD/scripts:/scripts" \
	-v "$PWD/tests:/tests" \
	-v "$PWD/results:/results" \
	ax25_tests \
	bats "${1:-/tests}"
