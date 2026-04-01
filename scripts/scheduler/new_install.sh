#!/bin/sh

SERVICE_EXEC=$2
GLOBAL_VERSION=$4

# # -------------------------------------------------------

create_firewall_from_template() {
  ADDITIONAL=""
    ADDITIONAL='"NAME": "firewall", "ROLES": "firewall", "NETWORK": "host", "SCALE": "0", "VOLUMES": [ { "SOURCE": "/etc/user/config/services", "DEST": "/services", "TYPE": "ro" }, { "SOURCE": "/etc/system/data/dns/hosts.local", "DEST": "/etc/dns/hosts.local", "TYPE": "ro" }, { "SOURCE": "/run", "DEST": "/run", "TYPE": "rw" }, { "SOURCE": "/var/run/docker.sock", "DEST": "/var/run/docker.sock", "TYPE": "rw" } ], "EXTRA": "--rm --privileged", "PRE_START": [], "DEPEND": [], "POST_START": [], "CMD": ""'

    echo '{
        "main": {
            "SERVICE_NAME": "framework-scheduler",
            "DOMAIN": "'$DOMAIN'"
        },
            "containers": [
                {
                "IMAGE": "'$DOCKER_REGISTRY_URL'/firewall:latest",
                "UPDATE": "true",
                "MEMORY": "64M",
                '$ADDITIONAL',
                "ENVS": [
                    { "CHAIN": "DOCKER-USER" },
                    { "SOURCE": "smarthostloadbalancer" },
                    { "TARGET": "safebox-webserver" },
                    { "TARGET_PORT": "8080" },
                    { "TYPE": "tcp" },
                    { "COMMENT": "proxy for safebox webserver" },
                    { "OPERATION": "'$ACTION'"}
                ]
                }
            ]
        }' | jq -r . > $SERVICE_DIR/firewall-safebox.json

}

create_domain_from_template() {
    
    ADDITIONAL=""
    ADDITIONAL='"NAME": "domain_checker", "ROLES": "domain_checker", "NETWORK": "host", "SCALE": "0", "EXTRA": "--rm --privileged", "PRE_START": [], "DEPEND": [], "POST_START": [], "CMD": ""'
    echo '{
        "main": {
            "SERVICE_NAME": "framework-scheduler",
            "DOMAIN": "'$DOMAIN'"
        },
        "containers": [
            {
            "IMAGE": "'$DOCKER_REGISTRY_URL'/domain-check:latest",
            "UPDATE": "true",
            "MEMORY": "64M",
            '$ADDITIONAL',
            "ENVS": [
                { "PROXY": "smarthostloadbalancer" },
                { "TARGET": "safebox-webserver" },
                { "PORT": "8080" },
                { "DOMAIN": "'$DOMAIN'" },
                { "SMARTHOST_PROXY_PATH": "/smarthost-domains" },
                { "OPERATION": "'$ACTION'"}
                ],
            "VOLUMES": [
                {
                "SOURCE": "/etc/user/config/smarthost-domains",
                "DEST": "/smarthost-domains",
                "TYPE": "rw"
                },
                { 
                "SOURCE": "/etc/system/data/dns/hosts.local",
                "DEST": "/etc/dns/hosts.local",
                "TYPE": "ro" 
                }
            ]
            }
        ]
    }' | jq -r . > $SERVICE_DIR/domain-safebox.json
}

create_remote_access_json() {

    local DOMAIN=$1
    local ACTION=$2

    if [[ -z "$ACTION"  && -f $SERVICE_DIR/firewall-safebox.json ]] || [[ -z "$ACTION"  && -f $SERVICE_DIR/domain-safebox.json ]]; then
        ACTION="MODIFY"
    elif [ -z "$ACTION" ]; then
        ACTION="CREATE"
    fi

    echo "safebox remote access for URL $DOMAIN $ACTION"

}