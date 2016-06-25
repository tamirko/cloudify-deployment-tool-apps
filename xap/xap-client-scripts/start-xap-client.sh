#!/bin/bash
set -x
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

deployment_id=$(ctx deployment id)

cd ~/
pushd ~/.ssh/
private_key_name_prefix="private_key_${deployment_id}"
private_key_name="${private_key_name_prefix}.pem"
windows_private_key_name="${private_key_name_prefix}.ppk"
ssh-keygen -t rsa -C "xap@gigaspaces.com" -f "${private_key_name}" -q -N ""
puttygen ${private_key_name} -o ${windows_private_key_name}
chmod 400 ${private_key_name}
chmod 400 ${windows_private_key_name}
cp -rp ${private_key_name} ~/
ctx instance runtime_properties pem ${private_key_name}
cp -rp ${windows_private_key_name} ~/
ctx instance runtime_properties ppk ${windows_private_key_name}

cat ${private_key_name}.pub >> authorized_keys
cp -rp ${private_key_name}.pub ~/
popd
COMMAND="python -m SimpleHTTPServer 8000"
ctx logger info "${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &
PID=$!
ctx instance runtime_properties pid ${PID}
ctx logger info "process id is ${PID}"
