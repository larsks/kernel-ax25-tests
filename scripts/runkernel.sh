#!/bin/bash

set -eu

fwcfg=()
fwcfg_args=()
fsdev_args=()
network_args=()
net_user=1
kernel_extra_args=""
initrd="boot/initrd"
kernel="boot/vmlinuz"
memory=1G

while getopts i:b:a:nk:f:m: ch; do
	case $ch in
	f)
		fwcfg+=("$OPTARG")
		;;
	k)
		kernel=$OPTARG
		;;
	i)
		initrd=$OPTARG
		;;
	n)
		net_user=0
		;;
	b)
		# map a local directory to a 9p filesystem
		# usage: -b <path>:<tag>[:<security_model>]
		mapfile -d: -t bindspec < <(echo -n "$OPTARG")
		bindsrc=${bindspec[0]}
		bindtag=${bindspec[1]}
		secmodel=${bindspec[2]:-none}
		fsdev_args+=(-fsdev "local,path=$bindsrc,id=$bindtag,security_model=${secmodel:-none}")
		fsdev_args+=(-device "virtio-9p-pci,id=$bindtag,fsdev=$bindtag,mount_tag=$bindtag")
		;;

	a)
		# append additional kernel fsdev_args
		kernel_extra_args="${kernel_extra_args:+${kernel_extra_args} }$OPTARG"
		;;

	m)
		memory=$OPTARG
		;;

	*)
		exit 2
		;;
	esac
done
shift $((OPTIND - 1))

if ((net_user)); then
	network_args+=(-nic "user,model=virtio-net-pci")
fi

for x in "${fwcfg[@]}"; do
	fwcfg_name=${x%%=*}
	fwcfg_val=${x#*=}
	fwcfg_args+=(-fw_cfg "name=$fwcfg_name,string=$fwcfg_val")
done

exec qemu-system-x86_64 -enable-kvm -m "$memory" \
	-kernel "$kernel" \
	-append "hostname=linux console=tty0 console=ttyS0,115200 no_timer_check net.ifnames=0 rw ${kernel_extra_args}" \
	-initrd "$initrd" \
	-smp 2 \
	"${fwcfg_args[@]}" \
	"${network_args[@]}" \
	"${fsdev_args[@]}" \
	"$@"
