#!/usr/bin/env bash

to_bytes() {
	amount=$1
	unit=$(printf "%s" "$amount" | tail -c 1)
	value="${amount%?}"

	if [ "$unit" = "G" ]; then
		echo $(("$value" * 1073741824))
		exit 0
	fi

	if [ "$unit" = "M" ]; then
		echo $(("$value" * 1048576))
		exit 0
	fi
}

to_megabytes() {
	amount=$1
	unit=$(printf "%s" "$amount" | tail -c 1)
	value="${amount%?}"

	if [ "$unit" = "G" ]; then
		echo $(("$value" * 1024))
		exit 0
	fi

	if [ "$unit" = "M" ]; then
		echo "$value"
		exit 0
	fi
}

contains() {
	list=$1
	target=$2

	for item in $list; do
		[ "$target" = "$item" ] && return
	done

	false
}

set -e

vm_name=$1
if [ -z "$vm_name" ]; then
	echo "VM name required"
	exit 1
fi

cpu_cores=$2
if [ -z "$cpu_cores" ]; then
	echo "CPU settings required"
	exit 1
fi

memory=$3
if [ -z "$memory" ]; then
	echo "RAM settings required"
	exit 1
fi

disk_size=$4
if [ -z "$disk_size" ]; then
	echo "Disk settings required"
	exit 1
fi

vm_ids=$(qm list | tail --lines=+2 | awk '{ print $1 }')
for i in $(seq 100 7999); do
	if ! contains "$vm_ids" "$i"; then
		vm_id="$i"
		break
	fi
done

if [ -z "$vm_id" ]; then
	echo "Could not assign a VM ID"
	exit 1
fi

template_id=$(qm list | grep 'vm-basic' | awk '{ print $1 }')
if [ -z "$template_id" ]; then
	echo "Could not find the template ID"
	exit 1
fi

snippets_directory="/var/lib/vz/snippets"
meta_data_file="$template_id"_"$vm_id"_meta-data.yml

cat >"$snippets_directory"/"$meta_data_file" <<-EOF
	instance-id: "iid-$vm_id"
	local-hostname: "$vm_name"
EOF

user_data_file="$template_id"_user-data.yml
vendor_file="$template_id"_vendor-data.yml

qm clone "$template_id" "$vm_id"

qm set "$vm_id" \
	--name "$vm_name" \
	--agent 1 \
	--cpu host --socket 1 --cores "$cpu_cores" \
	--memory "$(to_megabytes "$memory")" \
	--cicustom "user=local:snippets/$user_data_file,meta=local:snippets/$meta_data_file,vendor=local:snippets/$vendor_file" \
	--ipconfig0 ip=dhcp

qm disk resize "$vm_id" scsi0 "$(to_bytes "$disk_size")"
