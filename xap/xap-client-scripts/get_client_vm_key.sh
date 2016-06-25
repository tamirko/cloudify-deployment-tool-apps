#!/bin/bash
set -x

APT_GET_CMD=$(which apt-get)

deployment_id=$(ctx deployment id)


ctx logger info "id is `id`"

pushd /home/ubuntu/.ssh/

private_key_name_prefix="private_key_${deployment_id}"
private_key_name="${private_key_name_prefix}.pem"
#windows_private_key_name="${private_key_name_prefix}.ppk"

client_ip=$(ctx target instance runtime-properties client_ip_addr)
wget http://${client_ip}:8000/${private_key_name}.pub
currStatus=$?
ctx logger info "wget http://${client_ip}:8000/${private_key_name}.pub status is ${currStatus}"
chmod 644 ${private_key_name}.pub
cat ${private_key_name}.pub >> authorized_keys

popd
