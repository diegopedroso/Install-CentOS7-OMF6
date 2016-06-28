#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
XMPP_IP=$(/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
BROKER_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

add_hosts_config() {
    oldIFS=$IFS
    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        echo "${array[0]}   ${array[1]}" >> $INSTALLER_HOME/testbed-files/root/hosts
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
}

set_ips() {
    find $INSTALLER_HOME/config-files -type f -exec sed -i "s/<broker>/\BROKER_IP/g" {} +
    find $INSTALLER_HOME/config-files -type f -exec sed -i "s/<xmppserver>/\$XMPP_IP/g" {} +
}

set_resources_file() {
    python $INSTALLER_HOME/bin/resources/create_resources_input_file.py $INSTALLER_HOME/conf/nodes.conf \
    $INSTALLER_HOME/bin/resources/resources-template.json \
    $INSTALLER_HOME/testbed-files/root/resources.json
}

main() {
    add_hosts_config
    set_ips
    set_resources_file
}

main