#!/usr/bin/env bash

contains() {
	list=$1
	target=$2

	for item in $list; do
		[ "$target" = "$item" ] && return
	done

	false
}

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

vm_names=$(qm list | tail --lines=+2 | awk '{ print $2 }')
contains "$vm_names" "$vm_name"
