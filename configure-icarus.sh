#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ICARUS_NAMES=()

read_icarus_names() {
    oldIFS=$IFS

    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        if [[ ${array[0]} != *"#"* ]]; then
            ICARUS_NAMES+=(${array[0]})
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
}

find_cm_ip_by_icarus_name() {
    oldIFS=$IFS

    cm_ip=""
    while read line; do
        IFS=', ' read -r -a array <<< "$line"
        if [[ ${array[0]} == *"${1}"* ]]; then
            cm_ip=${array[4]}
        fi
        IFS=$'n'
    done < $INSTALLER_HOME/conf/nodes.conf
    IFS=$old_IFS
    echo ${cm_ip}
}

configure_icarus() {
    for node in "${ICARUS_NAMES[@]}"; do
        configure_omf_rc_on_icarus ${node}
    done
}

configure_omf_rc_on_icarus() {
    is_up=$(look_node_is_up $1)
    if [ $is_up -eq 1 ]; then
        echo "Node ${1} is up. Let's configure it."
        scp /config.yml root@$1:/etc/omf_rc
    else
        turn_on_node $1

        echo "Waiting for node to boot"

        WAITED_TIME=0
        while [ $(look_node_is_up $1) -eq 0 ] && [ $WAITED_TIME -le 20 ]; do
            echo -ne "Waiting for timeout $WAITED_TIME/20"'\r'
            WAITED_TIME=$[$WAITED_TIME +1]
        done

        if [ $(look_node_is_up $1) -eq 1 ]; then
            echo "Node ${1} is up. Let's configure it."
        else
            echo "Node ${1} is unreachable."
        fi

        if [ $is_up -eq 0 ]; then
            scp /config.yml root@$1:/etc/omf_rc
        fi
    fi
}

function print_array_with_separator { local IFS="$1"; shift; echo "$*"; }

turn_on_node() {
    cm_ip=$(find_cm_ip_by_icarus_name $1)
    curl http://${cm_ip}/on
}

look_node_is_up() {
    if ping -c 1 $1 &> /dev/null; then
      echo 1
    else
      echo 0
    fi
}

main() {
    read_icarus_names
    configure_icarus

}

main