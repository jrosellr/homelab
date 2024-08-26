#!/usr/bin/env bash

dir=$(dirname "$0")
template_id=$1
vm_id=$2
snippets_directory="/var/lib/vz/snippets"

mustache "$dir"/mustache_data.yml "$dir"/user-data.mustache.yml >"$snippets_directory"/"$template_id"_"$vm_id"_user-data.yml
mustache "$dir"/mustache_data.yml "$dir"/meta-data.mustache.yml >"$snippets_directory"/"$template_id"_"$vm_id"_meta-data.yml
cp "$dir"/../vendor.yml "$snippets_directory"/"$template_id"_"$vm_id"_vendor.yml
