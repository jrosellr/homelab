#!/usr/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

vm_name=$1
if [ -z "$vm_name" ]; then
	echo "VM name required"
	exit 1
fi

vm_template=$2
if [ -z "$vm_template" ]; then
	echo "VM template required"
	exit 1
fi

cpu_cores=$3
if [ -z "$cpu_cores" ]; then
	echo "CPU settings required"
	exit 1
fi

memory=$4
if [ -z "$memory" ]; then
	echo "RAM settings required"
	exit 1
fi

disk_size=$5
if [ -z "$disk_size" ]; then
	echo "Disk settings required"
	exit 1
fi

dir=$(dirname "$0")

"$dir"/templates/"$vm_template"/clone.sh "$vm_name" "$cpu_cores" "$memory" "$disk_size"
