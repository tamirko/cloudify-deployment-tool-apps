#!/bin/bash
interfacename=$(ctx node properties interfacename)
IP_ADDR=$(ip addr | grep inet | grep ${interfacename} | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
export XAP_LOOKUP_LOCATORS=$IP_ADDR
export XAP_NIC_ADDRESS=$IP_ADDR
if [ -f "/tmp/locators" ]; then
	for line in $(cat /tmp/locators); do
		XAP_LOOKUP_LOCATORS="${XAP_LOOKUP_LOCATORS}${line},"
	done
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim trailing comma
	export XAP_LOOKUP_LOCATORS
fi

XAPDIR=`cat /tmp/gsdir`  # left by install script

cfy logger info "shutting down with locators=${XAP_LOOKUP_LOCATORS} XAPDIR=$XAPDIR"
echo 1 | $XAPDIR/bin/gs.sh gsa shutdown
