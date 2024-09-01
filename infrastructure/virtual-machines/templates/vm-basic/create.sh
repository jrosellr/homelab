#!/usr/bin/env bash

set -e

contains() {
	list=$1
	target=$2

	for item in $list; do
		[ "$target" = "$item" ] && return
	done

	false
}

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

dir=$(dirname "$0")

vm_ids=$(qm list | tail --lines=+2 | awk '{ print $1 }')
for i in $(seq 9000 9999); do
	if ! contains "$vm_ids" "$i"; then
		vmid="$i"
		break
	fi
done

if [ -z "$vmid" ]; then
	echo "Unable to assign a new template ID"
	exit 1
fi

vm_names=$(qm list | tail --lines=+2 | awk '{ print $2 }')
if contains "$vm_names" "vm-basic" ; then
	echo "Template name already taken"
	exit 1
fi

image=$(yq '.image' "$dir/settings.yml")
image_path="/var/lib/vz/template/iso/$image"

if ! [ -f "$image_path" ] || ! [ -s "$image_path" ]; then
	echo "Image does not exist"
	exit 1
fi

qm create "$vmid" \
	--name "vm-basic" \
	--scsihw virtio-scsi-pci \
	--scsi0 local-lvm:0,import-from="$image_path" \
	--ide2 local-lvm:cloudinit \
	--boot order=scsi0 \
	--serial0 socket --vga serial0 \
	--net0 virtio,bridge="vmbr0"

qm template "$vmid"

snippets_directory="/var/lib/vz/snippets"
cp "$dir"/cloud-init/user-data.yml "$snippets_directory"/"$vmid"_user-data.yml
cp "$dir"/cloud-init/vendor-data.yml "$snippets_directory"/"$vmid"_vendor-data.yml
