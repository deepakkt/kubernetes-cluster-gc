## Kubernetes Cluster GC

This repository can be used to clean up cluster artifacts which may have become stale.

Actual artifacts to clean up will depend on how the cluster is setup and used. 

This cleanup job will remove

* Secrets
* Service Accounts

Of course, it is not difficult to extend this to other artifacts like Configmaps or other CRDs

Change the `gc-config.json` file to exclude namespaces and include prefixes of items to clean up

### How to setup execution

* Manually - on need basis. Just run `gc-core.sh` once dependencies are setup
* Via a cronjob - schedule `gc-core.sh` as per your needs
* Via a Kubernetes cronjob. Build the docker image with the `Dockerfile` and setup a Kubernetes cronjob (Setup a service account with the correct permissions)

### Dependencies

* Docker (if using `Dockerfile`). In which case, you can ignore the below requirements as the docker build will handle everything
* Bash
* kubectl setup with required permissions\
* jq
