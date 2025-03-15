#!/bin/sh

#! /bin/sh

cd /scripts
DEBUG_MODE=${DEBUG_MODE:-false}

DATE=$(date +%F-%H-%M-%S)

#DOCKER_REGISTRY_URL=${DOCKER_REGISTRY_URL:-registry.format.hu}
DOCKER_REGISTRY_URL=${DOCKER_REGISTRY_URL:-safebox}
USER_INIT_PATH=$USER_INIT_PATH
GLOBAL_VERSION=${GLOBAL_VERSION:-latest}
SERVICE_DIR=${SERVICE_DIR:-/etc/user/config/services}
SECRET_DIR=${SECRET_DIR:-/etc/user/secret}

SHARED=${SHARED:-/var/tmp/shared}

FRAMEWORK_SCHEDULER_IMAGE=${FRAMEWORK_SCHEDULER_IMAGE:-framework-scheduler}
FRAMEWORK_SCHEDULER_NAME=${FRAMEWORK_SCHEDULER_NAME:-framework-scheduler}
FRAMEWORK_SCHEDULER_NETWORK=${FRAMEWORK_SCHEDULER_NETWORK:-framework-network}
FRAMEWORK_SCHEDULER_NETWORK_SUBNET=${FRAMEWORK_SCHEDULER_NETWORK_SUBNET:-"172.19.255.0/24"}
FRAMEWORK_SCHEDULER_VERSION=${FRAMEWORK_SCHEDULER_VERSION:-latest}
RUN_FORCE=${RUN_FORCE:-false}

WEB_SERVER=${WEB_SERVER:-webserver}
WEB_IMAGE=${WEB_IMAGE:-web-installer}
WEBSERVER_PORT=${WEBSERVER_PORT:-8080}
WEBSERVER_VERSION=${WEBSERVER_VERSION:-latest}

if [[ -n "$DOCKER_REGISTRY_URL" && "$DOCKER_REGISTRY_URL" != "null" ]]; then
    SETUP="/setup"
else
    SETUP="setup"
    DOCKER_REGISTRY_URL=""
fi

SETUP_VERSION=${SETUP_VERSION:-$GLOBAL_VERSION}

# $DNS_PATH \
#$CA_FILE \
DNS_DIR="/etc/system/data/dns"
DNS="--env DNS_DIR=$DNS_DIR"
DNS_PATH="--volume $DNS_DIR:/etc/system/data/dns:rw"
HOST_FILE=$DNS_DIR"/hosts.local"
mkdir -p $DNS_DIR
touch $HOST_FILE

mkdir -p /etc/system/data/ssl/certs
mkdir -p /etc/system/data/ssl/keys

CA_PATH=/etc/system/data/ssl/certs
CA="--env CA_PATH=$CA_PATH"
CA_FILE="--volume $CA_PATH:$CA_PATH:ro"
mkdir -p $CA_PATH

VOLUME_MOUNTS="-v SYSTEM_DATA:/etc/system/data -v SYSTEM_CONFIG:/etc/system/config -v SYSTEM_LOG:/etc/system/log -v USER_DATA:/etc/user/data -v USER_CONFIG:/etc/user/config -v USER_SECRET:/etc/user/secret"

service_exec="/usr/bin/docker run --rm \
$DNS \
$CA \
-w /etc/user/config/services/ \
$VOLUME_MOUNTS \
-v /var/run/docker.sock:/var/run/docker.sock \
--env VOLUME_MOUNTS="$(echo $VOLUME_MOUNTS | base64 -w0)" \
--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
--env SETUP_VERSION=$SETUP_VERSION \
--env GLOBAL_VERSION=$GLOBAL_VERSION \
--env HOST_FILE=$HOST_FILE \
$DOCKER_REGISTRY_URL$SETUP:$SETUP_VERSION"

SHARED=${SHARED:-/var/tmp/shared}
TASK="scheduler-upgrade"

JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "UPGRADE_STATUS": "0" }' | jq -r . | base64 -w0) # install has started
install -m 664 -g 65534 /dev/null $SHARED/output/$TASK.json
echo $JSON_TARGET | base64 -d >$SHARED/output/$TASK.json

/usr/bin/docker rm -f framework-scheduler
$service_exec service-framework.containers.framework-scheduler start

JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "UPGRADE_STATUS": "1" }' | jq -r . | base64 -w0)
echo $JSON_TARGET | base64 -d >$SHARED/output/$TASK.json

/usr/bin/docker rm -f $HOSTNAME
