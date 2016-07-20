#!bin/bash

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

configure_icarus() {
    for node in "${ICARUS_NAMES[@]}"; do
        configure_omf_rc_on_icarus ${node}
    done
}

configure_omf_rc_on_icarus() {
    is_up=look_node_is_up $1
    if [ $is_up -eq 0 ]; then
        scp /config.yml root@$1:/etc/omf_rc
    else
        turn_on_node $1

        echo "Waiting for node to boot"

        WAITED_TIME=0
        while [ $(look_node_is_up icarus5) -eq 0 ] || [ $WAITED_TIME -eq 30 ]; do
            echo -ne "Waiting for timeout $WAITED_TIME/30"'\r'
            WAITED_TIME=$[$WAITED_TIME +1]
        done
        echo "Node ${1} is up. Let's configure it."
        configure_omf_rc_on_icarus $1
    fi
}

turn_on_node() {
    curl http://$1/on
}

look_node_is_up() {
    if ping -c 1 $1 &> /dev/null; then
      echo 1
    else
      echo 0
    fi
}

execute_tell_on() {
    omf6 tell -a on -t $(join , "${ICARUS_NAMES[@]}")
}

execute_omf6_stat() {
    omf6 stat -t $(join , "${ICARUS_NAMES[@]}")
}

function join { local IFS="$1"; shift; echo "$*"; }

main() {
    read_icarus_names
    configure_icarus

    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Test stat command"
    echo "2. Install only Broker"
    echo "3. Install only NITOS Testbed RCs"
    echo "4. Uninstall Broker"
    echo "5. Uninstall NITOS Testbed RCs"
    echo "6. Insert resources into Broker"
    echo "7. Install EC"
    echo "8. Uninstall EC"
    echo "9. Download baseline.ndz"
    echo "10. Exit"
    echo
    echo -n "Choose an option..."
    read option
    case $option in
    1) execute_omf6_stat ;;
    2)  ;;
    3)  ;;
    4)  ;;
    5)  ;;
    6)  ;;
    7)  ;;
    8)  ;;
    9)  ;;
    *) exit ;;
    esac
}

main