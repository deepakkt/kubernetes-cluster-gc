#!/bin/bash

## cleans up cluster resources for a single namespace
## can be called standalone as well if
##
## NAMESPACE, CONFIG_FILE and DRYRUN are set in the env
##


. gc-helper.sh
. gc-k8s-helper.sh

function parse_config() {
    SECRET_CLEANUP_PREFIXES=$(get_config secret_cleanup_prefixes true)
    SA_CLEANUP_PREFIXES=$(get_config service_account_cleanup_prefixes true)
    OLDER_THAN_DAYS=$(get_config cleanup_older_than_days false)
}

if [[ ! $NAMESPACE ]]; then
    logit "Namespace is a required parameter"
    exit 1
else
    logit "Namespace $NAMESPACE received"
fi

if [[ ! $CONFIG_FILE ]]; then
    logit "Config file must be set"
    logit "Set this under env var CONFIG_FILE"
    exit 1
fi

if [[ $DRYRUN == "true" ]]; then
    logit "Dry run mode requested"
    logit "No cluster resources will be modified"
fi

check_file $CONFIG_FILE
parse_config

TARGET_DATE=$(get_target_date $OLDER_THAN_DAYS)

process_artifact_in_namespace pipeline $NAMESPACE
process_artifact_in_namespace pipelinerun $NAMESPACE
process_artifact_in_namespace task $NAMESPACE
process_artifact_in_namespace taskrun $NAMESPACE
process_artifact_in_namespace secret $NAMESPACE
process_artifact_in_namespace serviceaccount $NAMESPACE