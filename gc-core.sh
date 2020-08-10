#!/bin/bash

## root function for cluster garbage cleanup
## only one optional parameter
## "--dry-run"
## to indicate dry run mode
##
## gc-config.json drives the actual cleanup
##
## Other required installations on the environment
##
## a) kubectl, connected to the cluster with required permissions
## b) jq utility

. gc-helper.sh
. gc-k8s-helper.sh

function parse_config() {
    IGNORE_NAMESPACES=$(get_config exclude_namespaces true)
    IGNORE_NAMESPACE_SUFFIXES=$(get_config exclude_namespace_suffixes true)
}

logit "Cluster resources cleanup"


DRYRUN=$1
if [[ $DRYRUN == "--dry-run" ]]; then
    logit "Dry run mentioned. No cluster resources will be modified"
    export DRYRUN=true
else
    logit "Dry run not mentioned. Eligible cluster resources will be purged"
    export DRYRUN=false
fi

export CONFIG_FILE="gc-config.json"
logit "Using configuration from $CONFIG_FILE"
cat $CONFIG_FILE | jq "."

parse_config

get_namespaces

while read EACH_NAMESPACE
do
    export NAMESPACE=$(get_artifact_name $EACH_NAMESPACE)

    NS_STATUS=$(evaluate_namespace_status $NAMESPACE)

    if [[ $NS_STATUS == "ignore" ]]; then
        logit "$NAMESPACE was ignored based on configuration"
    fi

    if [[ $NS_STATUS == "ignore-pr" ]]; then
        logit "$NAMESPACE was ignored because it was a pr environment"
    fi

    if [[ $NS_STATUS == "process" ]]; then
        logit "*** Now processing namespace $NAMESPACE ***"
        bash gc-namespace.sh
    fi
done <<< $NAMESPACES_LIST

logit "*** Processing complete! ***"