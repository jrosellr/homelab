#!/usr/bin/env bash

dir=$(dirname "$0")
vm_id=$1
vm_name=$2

cat >"$dir"/mustache_data.yml <<-EOF
---
vm_id: "$vm_id"
hostname: "$vm_name"
fqdn: "$vm_name.local"
password: $(openssl passwd -6 'debian')
ssh_key: $(cat ~/.ssh/id_rsa.pub)
---
EOF
