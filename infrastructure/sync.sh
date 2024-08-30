#!/usr/bin/env bash

set -e

function contains() {
	list=$1
	target=$2

	for item in $list; do
		if [ "$target" == "$item" ]; then
			echo "$item"
		fi
	done
}

guest_ids=$(qm list | tail --lines=+2 | awk '{ print $1 }')
template_keys=$(jq --raw-output '. | keys[]' templates.json)
for template_key in $template_keys; do
	template_id=$(jq --arg key "$template_key" '.[$key].id' templates.json)

	if [ -z "$(contains "$guest_ids" "$template_id")" ]; then
		template=$(jq --arg key "$template_key" '.[$key]' templates.json)
		name=$(echo "$template" | jq --raw-output '.name')
		image=$(echo "$template" | jq --raw-output '.image')

		./ci-templates/create.sh "$template_id" "$name" "$image"
	fi
done

vm_ids=$(jq --raw-output '.[].id' machines.json)
for vm_id in $vm_ids; do
	if [ -z "$(contains "$guest_ids" "$vm_id")" ]; then
		machine_config=$(jq --arg id "$vm_id" '.[] | select(.id == ($id | tonumber))' machines.json)
		template_config=$(jq '.' templates.json)
		./ci-templates/clone.sh "$machine_config" "$template_config"
	fi
done

template_ids=$(jq --raw-output '.[].id' templates.json)
for guest_id in $guest_ids; do
	if [ -z "$(contains "$vm_ids" "$guest_id")" ] && [ -z "$(contains "$template_ids" "$guest_id")" ]; then
		qm stop "$guest_id"
		qm destroy "$guest_id"
	fi
done
