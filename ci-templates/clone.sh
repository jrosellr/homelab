#!/usr/bin/env bash

set -e

function to_bytes() {
	echo $(("$1" * 1073741824))
}

dir=$(dirname "$0")

machine_config=$1
if [ -z "$machine_config" ]; then
	echo "Machine configuration required"
	exit 1
fi

templates=$2
if [ -z "$templates" ]; then
	echo "Template configuration required"
	exit 1
fi

template_name=$(echo "$machine_config" | jq --raw-output '.template')
template_config=$(echo "$templates" | jq --raw-output --arg name "$template_name" '. | to_entries[] | select(.value.name == $name) | .value')
if [ -z "$template_config" ]; then
	echo "Template not found"
	exit 1
fi

template_id=$(echo "$template_config" | jq '.id')

echo "Starting clone from $template_id"

vm_id=$(echo "$machine_config" | jq --raw-output '.id')
vm_name=$(echo "$machine_config" | jq --raw-output '.hostname')

"$dir"/"$template_name"/create_mustache_data.sh "$vm_id" "$vm_name"
"$dir"/"$template_name"/deploy_ci_data.sh "$template_id" "$vm_id"

user_data_file="$template_id"_"$vm_id"_user-data.yml
meta_data_file="$template_id"_"$vm_id"_meta-data.yml
vendor_file="$template_id"_"$vm_id"_vendor.yml

qm clone "$template_id" "$vm_id"

vm_cores=$(echo "$machine_config" | jq --raw-output '.cpu.cores')
vm_memory=$(echo "$machine_config" | jq --raw-output '.memory')

qm set "$vm_id" \
	--name "$vm_name" \
	--agent 1 \
	--cpu host --socket 1 --cores "$vm_cores" \
	--memory "$vm_memory" \
	--cicustom "user=local:snippets/$user_data_file,meta=local:snippets/$meta_data_file,vendor=local:snippets/$vendor_file" \
	--ipconfig0 ip=dhcp

vm_disk_size=$(echo "$machine_config" | jq --raw-output '.disk.size')

qm disk resize "$vm_id" scsi0 "$(to_bytes "$vm_disk_size")"
