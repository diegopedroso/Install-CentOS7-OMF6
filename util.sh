printMessage() {
    message="$1"
    message_size=${#message}

    number_of_cols=$COLUMNS
    for i in $(seq 1 $((number_of_cols - message_size - 1))); do
        if [ "$i" != $(((number_of_cols - message_size - 1)/2)) ]; then
            echo -n "#"
        else
            echo -n  $message
        fi
    done
    echo ""
}