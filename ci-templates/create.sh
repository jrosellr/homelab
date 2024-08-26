#!/usr/bin/env bash

set -e

vmid=$1
if [ -z "$vmid" ]; then
	echo "VM ID required"
	exit 1
fi

template_name=$2
if [ -z "$template_name" ]; then
	echo "VM template name required"
	exit 1
fi

image=$3
if [ -z "$image" ]; then
	echo "VM image required"
	exit 1
fi

vm_name="tmp-$vmid"
default_node_bridge="vmbr0"

qm create "$vmid" \
	--name "$vm_name" \
	--scsihw virtio-scsi-pci \
	--scsi0 local-lvm:0,import-from="/var/lib/vz/template/iso/$image" \
	--ide2 local-lvm:cloudinit \
	--boot order=scsi0 \
	--serial0 socket --vga serial0 \
	--net0 virtio,bridge="$default_node_bridge"

qm set "$vmid" --name "$template_name"

qm template "$vmid"
