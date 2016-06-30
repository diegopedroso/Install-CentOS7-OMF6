#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BROKER_INTERFACE="eth0"
AMQP_INTERFACE="eth0"
XMPP_INTERFACE="eth1"

add_hosts_config() {
    oldIFS=$IFS
    echo $'\n' >> $INSTALLER_HOME/testbed-files/root/hosts
    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        if [[ ${array[0]} != *"#"* ]]; then
            echo -e "${array[1]}\t${array[0]}" >> $INSTALLER_HOME/testbed-files/root/hosts
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
}

set_service_interface() {
    oldIFS=$IFS

    while read line; do
        IFS='=' read -r -a array <<< "$line"
        if [[ ${array[0]} = *"broker"* ]]; then
            BROKER_INTERFACE=${array[1]}
        elif [[ ${array[0]} = *"amqpserver"* ]]; then
            AMQP_INTERFACE=${array[1]}
        elif [[ ${array[0]} = *"xmppserver"* ]]; then
            XMPP_INTERFACE=${array[1]}
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/interface-service-map.conf
    IFS=$old_IFS
}

set_ips() {
    set_service_interface

    XMPP_IP=$(/sbin/ifconfig $XMPP_INTERFACE | grep 'inet end.:' | cut -d: -f2 | awk '{ print $1}')
    BROKER_IP=$(/sbin/ifconfig $BROKER_INTERFACE | grep 'inet end.:' | cut -d: -f2 | awk '{ print $1}')
    AMQP_IP=$(/sbin/ifconfig $AMQP_INTERFACE | grep 'inet end.:' | cut -d: -f2 | awk '{ print $1}')

    if [ -z "$XMPP_IP" -o "$XMPP_IP" == " " ]; then
        XMPP_IP=$(/sbin/ifconfig $XMPP_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
    fi

    if [ -z "$BROKER_IP" -o "$BROKER_IP" == " " ]; then
        BROKER_IP=$(/sbin/ifconfig $BROKER_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
    fi

    if [ -z "$AMQP_IP" -o "$AMQP_IP" == " " ]; then
        AMQP_IP=$(/sbin/ifconfig $AMQP_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
    fi

    find $INSTALLER_HOME/testbed-files -type f -exec sed -i "s/<broker>/$BROKER_IP/g" {} +
    find $INSTALLER_HOME/testbed-files -type f -exec sed -i "s/<amqpserver>/$AMQP_IP/g" {} +
    find $INSTALLER_HOME/testbed-files -type f -exec sed -i "s/<xmppserver>/$XMPP_IP/g" {} +
    find $INSTALLER_HOME/testbed-files -type f -exec sed -i "s/<xmppserver-interface>/$XMPP_INTERFACE/g" {} +
}

set_resources_file() {
    python $INSTALLER_HOME/bin/resources/create_resources_input_file.py $INSTALLER_HOME/conf/nodes.conf \
    $INSTALLER_HOME/bin/resources/resources-template.json \
    $INSTALLER_HOME/testbed-files/root/resources.json
}

main() {
    set_resources_file
    add_hosts_config
    set_ips
}

main