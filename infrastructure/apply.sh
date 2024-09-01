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

dir=$(dirname "$0")
resources=$(yq -o json '.resources' "$dir/resources.yml")
vm_names=$(echo "$resources" | jq --raw-output '.[] | select(.type == "vm") | .name')

for vm_name in $vm_names; do
	if ! "$dir"/virtual-machines/vm_exists.sh "$vm_name"; then
		vm_settings=$(echo "$resources" | jq --arg name "$vm_name" --compact-output '.[] | select(.name == $name)')
		vm_template=$(echo "$vm_settings" | jq --raw-output '.template')

		if ! "$dir"/virtual-machines/vm_exists.sh "$vm_template"; then
			echo "The required template does not exist $vm_template"
			exit 1
		fi

		cpu_cores="$(echo "$vm_settings" | jq --raw-output '.compute."cpu-cores"')"
		memory="$(echo "$vm_settings" | jq --raw-output '.compute.memory')"
		disk_size="$(echo "$vm_settings" | jq --raw-output '.storage."disk-size"')"

		"$dir"/virtual-machines/clone.sh "$vm_name" "$vm_template" "$cpu_cores" "$memory" "$disk_size"
	fi
done
