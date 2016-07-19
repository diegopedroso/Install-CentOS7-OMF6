#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $INSTALLER_HOME/variables.conf

CONTROL_NETWORK_INTERFACE="eth1"

create_tmp_testbed_files() {
    mkdir -p /tmp/testbed-files
    cp -rf $INSTALLER_HOME/testbed-files /tmp/testbed-files
}

add_hosts_config() {
    oldIFS=$IFS
    echo $'\n' >> /tmp/testbed-files/root/hosts
    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        if [[ ${array[0]} != *"#"* ]]; then
            echo -e "${array[1]}\t${array[0]}" >> /tmp/testbed-files/root/hosts
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
}

set_service_interface() {
    oldIFS=$IFS

    while read line; do
        IFS='=' read -r -a array <<< "$line"
        if [[ ${array[0]} = *"control_network"* ]]; then
            CONTROL_NETWORK_INTERFACE=${array[1]}
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/interface-network-map.conf
    IFS=$old_IFS
}

set_ips() {
    set_service_interface

    CONTROL_NETWORK_IP=$(/sbin/ifconfig $CONTROL_NETWORK_INTERFACE | grep 'inet end.:' | cut -d: -f2 | awk '{ print $1}')

    if [ -z "$CONTROL_NETWORK_IP" -o "$CONTROL_NETWORK_IP" == " " ]; then
        CONTROL_NETWORK_IP=$(/sbin/ifconfig $CONTROL_NETWORK_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
    fi

    IP_BASE_DHCP_RANGE=$(echo $CONTROL_NETWORK_IP | cut -d"." -f1-3)

    find /tmp/testbed-files -type f -exec sed -i "s/<control_network>/$CONTROL_NETWORK_IP/g" {} +
    find /tmp/testbed-files -type f -exec sed -i "s/<control_network_interface>/$CONTROL_NETWORK_INTERFACE/g" {} +
    find /tmp/testbed-files -type f -exec sed -i "s/<ip_base_dhcp_range>/$IP_BASE_DHCP_RANGE/g" {} +
}

set_domain() {

    find /tmp/testbed-files -type f -exec sed -i "s/<xmpp_domain>/$XMPP_DOMAIN/g" {} +
    find /tmp/testbed-files -type f -exec sed -i "s/<domain>/$DOMAIN/g" {} +
}

set_resources_file() {
    python $INSTALLER_HOME/bin/resources/create_resources_input_file.py $INSTALLER_HOME/conf/nodes.conf \
    $INSTALLER_HOME/bin/resources/resources-template.json \
    /tmp/testbed-files/root/resources.json
}

main() {
    create_tmp_testbed_files
    set_resources_file
    add_hosts_config
    set_ips
    set_domain
}

main