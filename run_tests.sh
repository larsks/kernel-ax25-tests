#!/bin/bash

docker_opts=()

while getopts t ch; do
	case $ch in
	t)
		docker_opts+=(-it)
		;;
	*)
		exit 2
		;;
	esac
done
shift $((OPTIND - 1))

if [[ -z "$*" ]]; then
	set -- bats /tests
fi

docker build -t ax25_tests .

docker run --rm --init --name "$(mktemp -u ax25_tests_XXXXXX)" \
	"${docker_opts[@]}" \
	--label ax25tests \
	--cap-add NET_ADMIN \
	--device /dev/net/tun \
	--device /dev/kvm \
	-v "$PWD/boot:/boot" \
	-v "$PWD/scripts:/scripts" \
	-v "$PWD/tests:/tests" \
	-v "$PWD/results:/results" \
	ax25_tests \
	"${@}"
