### kubernetes helper functions
### not to be intended to run standalone

function get_namespaces() {
    NAMESPACES_LIST=$(kubectl get namespace -o json \
                     | jq '.items[]' \
                     | jq -r '.metadata.name + " " + .metadata.creationTimestamp')
}

function get_cluster_entries() {
    ## pass two parameters
    ## namespace as first parameter
    ## artifact type as second parameter
    ##
    ## it will just return name and creation timestamp
    ## as output

    local PROCESS_NAMESPACE=$1
    local ARTIFACT_TYPE=$2
    local KUBECTL_COMMAND="kubectl get $ARTIFACT_TYPE -n $PROCESS_NAMESPACE -o json"

    CLUSTER_RETURN_VALUES=$($KUBECTL_COMMAND | jq '.items[]' \
                    | jq -r '.metadata.name + " " + .metadata.creationTimestamp')
}


function delete_cluster_entries() {
    # needs global variable DRYRUN
    # and must be set to true for
    # dry run

    local ARTIFACT_NAME=$1
    local ARTIFACT_NAMESPACE=$2
    local ARTIFACT_TYPE=$3

    if [[ $DRYRUN == "true" ]]; then
        logit "Dry run => $ARTIFACT_TYPE/$ARTIFACT_NAME deleted in $ARTIFACT_NAMESPACE"
    else
        logit $(kubectl delete $ARTIFACT_TYPE -n $ARTIFACT_NAMESPACE $ARTIFACT_NAME)
    fi

    return 0
}


function get_artifact_name() {
    local INPUT_ENTRY=$1
    local ARTIFACT_NAME=$(echo $INPUT_ENTRY | cut -d " " -f1)
    echo $ARTIFACT_NAME
}


function get_artifact_create_date() {
    local INPUT_ENTRY=$1
    local ARTIFACT_TS=$(echo $INPUT_ENTRY | cut -d " " -f2)
    local ARTIFACT_DATE=$(echo $ARTIFACT_TS | cut -d "T" -f1)
    echo $ARTIFACT_DATE
}


function evaluate_artifact_status() {
    # this function expects
    # SECRET_CLEANUP_PREFIXES and SA_CLEANUP_PREFIXES
    # to be available in global scope

    local ARTIFACT_NAME=$1
    local ARTIFACT_TYPE=$2
    local ARTIFACT_DATE=$3
    local TARGET_DATE=$4

    if [[ $ARTIFACT_TYPE == "pipeline" || $ARTIFACT_TYPE == "pipelinerun"  \
            || $ARTIFACT_TYPE == "task" || $ARTIFACT_TYPE == "taskrun" ]]; then
        if [[ $ARTIFACT_DATE < $TARGET_DATE ]]; then
            echo "delete"
        else
            echo "retain"
        fi
        return 0
    fi

    if [[ $ARTIFACT_TYPE == "secret" ]]; then
        local ARTIFACT_MATCH=$(match_prefix $ARTIFACT_NAME $SECRET_CLEANUP_PREFIXES)
        if [[ $ARTIFACT_MATCH == "no-match" ]]; then
            echo "retain-no-match"
            return 0
        fi
    fi

    if [[ $ARTIFACT_TYPE == "serviceaccount" ]]; then
        local ARTIFACT_MATCH=$(match_prefix $ARTIFACT_NAME $SA_CLEANUP_PREFIXES)
        if [[ $ARTIFACT_MATCH == "no-match" ]]; then
            echo "retain-no-match"
            return 0
        fi
    fi

    if [[ $ARTIFACT_DATE < $TARGET_DATE ]]; then
        echo "delete"
    else
        echo "retain"
    fi
    return 0
}


function process_artifact_in_namespace() {
    local ARTIFACT_TYPE=$1
    local ARTIFACT_NAMESPACE=$2
    get_cluster_entries $NAMESPACE $ARTIFACT_TYPE

    local ARTIFACTS_READ=0
    local ARTIFACTS_DELETED=0
    local ARTIFACTS_RETAINED=0
    local ARTIFACTS_NOT_MATCHED=0

    while read EACH_ENTRY
    do
        ARTIFACT_NAME=$(get_artifact_name "$EACH_ENTRY")
        ARTIFACT_DATE=$(get_artifact_create_date "$EACH_ENTRY")
        ARTIFACT_STATUS=$(evaluate_artifact_status $ARTIFACT_NAME $ARTIFACT_TYPE $ARTIFACT_DATE $TARGET_DATE)
        let "ARTIFACTS_READ = ARTIFACTS_READ + 1"

        if [[ $ARTIFACT_STATUS == "delete" ]]; then
            logit "$ARTIFACT_TYPE $ARTIFACT_NAME ($ARTIFACT_DATE) is older than $TARGET_DATE. It will be purged"
            delete_cluster_entries $ARTIFACT_NAME $NAMESPACE $ARTIFACT_TYPE
            let "ARTIFACTS_DELETED = ARTIFACTS_DELETED + 1"
        else
            if [[ $ARTIFACT_STATUS == "retain-no-match" ]]; then
                logit "$ARTIFACT_TYPE $ARTIFACT_NAME ($ARTIFACT_DATE) did not match configuration prefix. It will be retained"
                let "ARTIFACTS_NOT_MATCHED = ARTIFACTS_NOT_MATCHED + 1"
            else
                logit "$ARTIFACT_TYPE $ARTIFACT_NAME ($ARTIFACT_DATE) within threshold of $TARGET_DATE. It will be retained"
                let "ARTIFACTS_RETAINED = ARTIFACTS_RETAINED + 1"
            fi
        fi
    done <<< $CLUSTER_RETURN_VALUES

    logit "*** Namespace $ARTIFACT_NAMESPACE: $ARTIFACTS_READ ${ARTIFACT_TYPE}s read for $NAMESPACE - $ARTIFACTS_DELETED deleted, $ARTIFACTS_NOT_MATCHED unmatched, $ARTIFACTS_RETAINED retained ***"
}

function evaluate_namespace_status() {
    local INPUT_NAMESPACE=$1

    IGNORE_STATUS=$(match_equal $INPUT_NAMESPACE $IGNORE_NAMESPACES)

    if [[ $IGNORE_STATUS == "match" ]]; then
        echo "ignore"
        return 0
    fi

    IGNORE_STATUS_2=$(match_suffix $INPUT_NAMESPACE $IGNORE_NAMESPACE_SUFFIXES)

    if [[ $IGNORE_STATUS_2 == "match" ]]; then
        echo "ignore"
        return 0
    fi

    if [[ $INPUT_NAMESPACE =~ [a-zA-Z0-9-]+-pr-[0-9]+ ]]; then
        echo "ignore-pr"
        return 0
    fi

    echo "process"
    return 0
}