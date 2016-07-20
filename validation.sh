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

function print_array_with_separator { local IFS="$1"; shift; echo "$*"; }

look_node_is_up() {
    if ping -c 1 $1 &> /dev/null; then
      echo 1
    else
      echo 0
    fi
}

execute_tell_on() {
    omf6 tell -a on -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

execute_omf6_stat() {
    omf6 stat -t $(print_array_with_separator , "${ICARUS_NAMES[@]}")
}

main() {
    read_icarus_names

    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Configure omf_rc on Icarus nodes"
    echo "2. Test stat command"
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
    1) $INSTALLER_HOME/configure-icarus.sh ;;
    2) execute_omf6_stat;;
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