#!/bin/bash
set -x
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)


cd ~/
touch xxx
touch yyy
COMMAND="python -m SimpleHTTPServer 8000"
ctx logger info "${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &
PID=$!
ctx instance runtime_properties pid ${PID}
ctx logger info "process id is ${PID}"
