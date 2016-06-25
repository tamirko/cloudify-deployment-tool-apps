#!/bin/bash
set -x

APT_GET_CMD=$(which apt-get)

deployment_id=$(ctx deployment id)


pushd ~/.ssh/

private_key_name_prefix="private_key_${deployment_id}"
private_key_name="${private_key_name_prefix}.pem"
#windows_private_key_name="${private_key_name_prefix}.ppk"

client_ip=$(ctx target instance runtime-properties client_ip_addr)
wget ${client_ip}:8000/${private_key_name}.pub
chmod 644 ${private_key_name}.pub
cat ${private_key_name}.pub >> authorized_keys

popd
