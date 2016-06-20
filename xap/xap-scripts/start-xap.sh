#!/bin/bash

export LOOKUPGROUPS=
export XAP_GSA_OPTIONS=$(ctx -node properties GSA_JAVA_OPTIONS)
export XAP_LUS_OPTIONS=$(ctx node properties LUS_JAVA_OPTIONS)
export XAP_GSM_OPTIONS=$(ctx node properties GSM_JAVA_OPTIONS)
export XAP_GSC_OPTIONS=$(ctx node properties GSC_JAVA_OPTIONS)
gsm_cnt=$(ctx -j node properties gsm_cnt)
global_gsm_cnt=$(ctx -j node properties global_gsm_cnt)
lus_cnt=$(ctx -j node properties lus_cnt)
gsc_cnt=$(ctx -j node properties gsc_cnt)
global_lus_cnt=$(ctx -j node properties global_lus_cnt)
lrmi_comm_min_port=$(ctx node properties lrmi_comm_min_port)
lrmi_comm_max_port=$(ctx node properties lrmi_comm_max_port)
zones=$(ctx node properties zones)
interfacename=$(ctx node properties interfacename)
ctx download-resource xap-scripts/startgsc.groovy '@{"target_path": "/tmp/startgsc.groovy"}'

sudo ulimit -n 32000
sudo ulimit -u 32000

XAPDIR=`cat /tmp/gsdir`  # left by install script

ctx logger info "gsm=$gsm_cnt gsc=$gsc_cnt lus=$lus_cnt"

ip=$(ctx instance runtime_properties ip_address)

IP_ADDR=$ip
ctx logger info "IP_ADDR is ${IP_ADDR}"

XAP_LOOKUP_LOCATORS=$IP_ADDR  #default to local
if [ -f "/tmp/locators" ]; then
	XAP_LOOKUP_LOCATORS=""
	for line in $(cat /tmp/locators); do
		if [ "$line" != "$IP_ADDR" ]; then
			XAP_LOOKUP_LOCATORS="${line}"
			ctx logger info "XAP_LOOKUP_LOCATORS new from /tmp/locators is ${XAP_LOOKUP_LOCATORS}"
		fi
	done
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim trailing comma
  	XAP_LOOKUP_LOCATORS=${XAP_LOOKUP_LOCATORS%%,}  #trim trailing comma
fi
if [ "$lus_cnt" != 0 ]; then
	echo "${IP_ADDR}" >> /tmp/locators
	#XAP_LOOKUP_LOCATORS="${IP_ADDR},${XAP_LOOKUP_LOCATORS}"
fi

ctx logger info "final XAP_LOOKUP_LOCATORS is ${XAP_LOOKUP_LOCATORS}"
export XAP_LOOKUP_LOCATORS
IP_ADDR=$(ip addr | grep inet | grep ${interfacename} | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
export XAP_NIC_ADDRESS=${IP_ADDR}

export XAP_EXT_OPTIONS="-Dcom.gs.multicast.enabled=false -Dcom.gs.transport_protocol.lrmi.bind-port=$lrmi_comm_min_port-$lrmi_comm_max_port -Dcom.gigaspaces.start.httpPort=7104 -Dcom.gigaspaces.system.registryPort=7102"

export XAP_GSC_OPTIONS="$XAP_GSC_OPTIONS -Dcom.gs.zones=${zones}"

PS=`ps -eaf|grep -v grep|grep GSA`

if [ "$PS" = "" ]; then  #no gsa running already

    if [ $lus_cnt -gt 0 ]; then
        # Manager
        DIR1=/tmp
        mkdir -p $DIR1/tmpstuff
        pushd $DIR1/tmpstuff
        ctx logger info "Installing influxdb"
        currWd="`pwd`"
        ctx logger info "currWd ${currWd}"
        wget https://dl.influxdata.com/influxdb/releases/influxdb_0.13.0_amd64.deb
        currStatus=$?
        ctx logger info "After wget currStatus ${currStatus}"

        sudo dpkg -i influxdb_0.13.0_amd64.deb
        currStatus=$?
        ctx logger info "After dpkg influxdb_0 currStatus ${currStatus}"

        sudo /etc/init.d/influxdb start
        currStatus=$?
        ctx logger info "After influxdb start currStatus ${currStatus}"

        /usr/bin/influx -execute "CREATE DATABASE mydb"
        currStatus=$?
        ctx logger info "After CREATE DATABASE currStatus ${currStatus}"

        ctx logger info "Installing grafana"
        wget https://grafanarel.s3.amazonaws.com/builds/grafana_3.0.4-1464167696_amd64.deb
        currStatus=$?
        ctx logger info "After wget grafana currStatus ${currStatus}"

        sudo dpkg -i grafana_3.0.4-1464167696_amd64.deb
        currStatus=$?
        ctx logger info "After dpkg grafana_3 currStatus ${currStatus}"

        sudo service grafana-server start
        currStatus=$?
        ctx logger info "After grafana-server start currStatus ${currStatus}"
        popd
    else
        #Container
        ctx logger info "Configuring influxdb in a container"
        metricsFile=$XAPDIR/config/metrics/metrics.xml
        sudo sed -i -e "s/localhost/$XAP_LOOKUP_LOCATORS/g" ${metricsFile}
        influxLine=`grep -n "reporter name=\"influxdb\"" ${metricsFile} | awk -F: ' {print $1}'`
        commentLine=`expr $influxLine - 1`
        sed -i -e "${commentLine}s/.*//" ${metricsFile}
        endOfInfluxLine=`grep -n "\/reporter>" ${metricsFile} | awk -F: ' {print $1}'`
        afterInfluxLine=`expr $endOfInfluxLine + 1`
        sed -i -e "${afterInfluxLine}s/.*//" ${metricsFile}

        ctx logger info "Configuring grafana in a container"
        grafanaLine=`grep -n "\<grafana u" ${metricsFile} | awk -F: ' {print $1}'`
        commentLine=`expr $grafanaLine - 1`
        sed -i -e "${commentLine}s/.*//" ${metricsFile}
        endOfGrafanaLine=`grep -n "\/grafana>" ${metricsFile} | awk -F: ' {print $1}'`
        afterGrafanaLine=`expr $endOfGrafanaLine + 1`
        sed -i -e "${afterGrafanaLine}s/.*//" ${metricsFile}
    fi

	ctx logger info "running $XAPDIR/bin/gs-agent.sh gsa.global.lus $global_lus_cnt gsa.lus $lus_cnt gsa.global.gsm $global_gsm_cnt gsa.gsm $gsm_cnt gsa.gsc $gsc_cnt"

	nohup $XAPDIR/bin/gs-agent.sh gsa.global.lus $global_lus_cnt gsa.lus $lus_cnt gsa.global.gsm $global_gsm_cnt gsa.gsm $gsm_cnt gsa.gsc $gsc_cnt >/tmp/xap.nohup.out 2>&1 &

        sleep 10

else #running local cloud

	ctx logger info "running gs-agent.sh"

	if [ $gsm_cnt -gt 0 ]; then
		echo $gsm_cnt|$XAPDIR/bin/gs.sh gsa start-gsm
	fi
	if [ $lus_cnt -gt 0 ]; then
		echo $lus_cnt|$XAPDIR/bin/gs.sh gsa start-lus
	fi
	if [ $gsc_cnt -gt 0 ]; then
		GROOVY=$XAPDIR/tools/groovy/bin/groovy
		ctx logger info "calling:  $GROOVY /tmp/startgsc.groovy ${interfacename} ${gsc_cnt} \"$XAP_GSC_OPTIONS $XAP_EXT_OPTIONS\" ${IP_ADDR}"
		$GROOVY /tmp/startgsc.groovy ${interfacename} ${gsc_cnt} "$XAP_GSC_OPTIONS $XAP_EXT_OPTIONS" ${IP_ADDR} > "/tmp/startgsc_xap$(date).log"
	fi

fi
