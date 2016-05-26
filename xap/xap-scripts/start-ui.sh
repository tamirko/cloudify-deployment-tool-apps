#!/bin/bash

source ${CLOUDIFY_LOGGING}
webui_port=$(ctx node properties webui_port)
XAPDIR=`cat /tmp/gsdir`  # left by install script
interfacename=$(ctx node properties interfacename)
IP_ADDR=$(ip addr | grep inet | grep ${interfacename} | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
IP_ADDR=$(wget -qO- ipinfo.io/ip)
export XAP_LOOKUP_LOCATORS=$IP_ADDR
if [ -f "/tmp/locators" ]; then
XAP_LOOKUP_LOCATORS=""
	for line in $(cat /tmp/locators); do
		XAP_LOOKUP_LOCATORS="${XAP_LOOKUP_LOCATORS}${line},"
	done
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim trailing comma
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim another trailing comma
fi

XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim another trailing comma
export XAP_LOOKUP_LOCATORS
export XAP_NIC_ADDRESS=${IP_ADDR}
export XAP_EXT_OPTIONS="-Dcom.gs.multicast.enabled=false -Dcom.gs.transport_protocol.lrmi.bind-port=7122-7222 -Dcom.gigaspaces.start.httpPort=7104 -Dcom.gigaspaces.system.registryPort=7102"

ctx logger info "locators=$XAP_LOOKUP_LOCATORS"

export WEBUI_PORT=$webui_port

nohup $XAPDIR/bin/gs-webui.sh >/tmp/webui.nohup.out 2>&1 &

echo $! > /tmp/webui.pid

ctx logger info "webui started"
