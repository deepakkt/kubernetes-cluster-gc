FROM ubuntu:bionic

RUN apt-get install jq

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.8/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

RUN mkdir -p /usr/cluster-gc

COPY . /usr/cluster-gc/

WORKDIR /usr/cluster-gc
ENTRYPOINT ["bash", "gc-core.sh"]