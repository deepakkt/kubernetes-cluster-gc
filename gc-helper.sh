function logit() {
    DATENOW=$(date "+%Y-%m-%dT%H:%M:%S")
    echo "$DATENOW $@"
}


function check_success() {
    RETURN_CODE=$1

    if [[ $RETURN_CODE != "0" ]]; then
        logit "No zero return code: ${@:2}"
        logit "Aborting execution"
        exit 1
    fi

    return 0
}


function check_file() {
    FILENAME=$1

    if [[ ! -f $FILENAME ]]; then
        logit "File $FILENAME is missing"
        logit "Aborting execution"
        exit 1
    fi

    return 0
}


function get_config() {
    PARM_NAME=$1
    IS_ARRAY=$2

    if [[ $IS_ARRAY == "true" ]]; then
        CONFIG_VALUE=$(cat $CONFIG_FILE | jq -r ".$PARM_NAME[]")
        check_success $? "Check for $PARM_NAME in $CONFIG_FILE"
    else
        CONFIG_VALUE=$(cat $CONFIG_FILE | jq -r ".$PARM_NAME")

        if [[ $CONFIG_VALUE == "null" ]]; then
            check_success 1 "Check for config cleanup_older_than_days in $CONFIG_FILE"
        fi
    fi

    echo $CONFIG_VALUE
}


function get_target_date() {
    local SUBTRACT_DATE=$1
    echo $(date -I -d "-${SUBTRACT_DATE} days")
}


function match_prefix() {
    local PREFIX_LIST=${@:2}
    local ENTRY_TO_CHECK=$1

    for EACH_PREFIX in $PREFIX_LIST
    do
        if [[ $ENTRY_TO_CHECK = $EACH_PREFIX* ]]; then
            echo "match"
            return 0
        fi
    done

    echo "no-match"
    return 0
}


function match_equal() {
    local PREFIX_LIST=${@:2}
    local ENTRY_TO_CHECK=$1

    for EACH_PREFIX in $PREFIX_LIST
    do
        if [[ $ENTRY_TO_CHECK = $EACH_PREFIX ]]; then
            echo "match"
            return 0
        fi
    done

    echo "no-match"
    return 0
}


function match_suffix() {
    local SUFFIX_LIST=${@:2}
    local ENTRY_TO_CHECK=$1

    for EACH_SUFFIX in $SUFFIX_LIST
    do
        if [[ $ENTRY_TO_CHECK =~ ${EACH_SUFFIX}$ ]]; then
            echo "match"
            return 0
        fi
    done

    echo "no-match"
    return 0
}
