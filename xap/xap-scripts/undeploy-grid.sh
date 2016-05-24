#!/bin/bash

GRID_NAME=$1

XAPDIR=`cat /tmp/gsdir`  # left by install script
interfacename=$(ctx node properties interfacename)
IP_ADDR=$(ip addr | grep inet | grep ${interfacename} | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
export XAP_LOOKUP_LOCATORS=$IP_ADDR
export XAP_NIC_ADDRESS=$IP_ADDR
if [ -f "/tmp/locators" ]; then
	XAP_LOOKUP_LOCATORS=""
	for line in $(cat /tmp/locators); do
		XAP_LOOKUP_LOCATORS="${XAP_LOOKUP_LOCATORS}${line},"
	done
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim trailing comma
	export XAP_LOOKUP_LOCATORS
fi

ctx logger info "deploying space, locators=$XAP_LOOKUP_LOCATORS"
ctx logger info "space name, $GRID_NAME"
ctx logger info "schema, $SCHEMA"
ctx logger info "xap dir, $XAPDIR"

$XAPDIR/bin/gs.sh undeploy ${GRID_NAME}
