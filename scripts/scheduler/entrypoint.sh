#! /bin/sh

cd /scripts
DEBUG_MODE=${DEBUG_MODE:-false}

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
REDIS_SERVER=${REDIS_SERVER:-redis-server}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_IMAGE=${REDIS_IMAGE:-redis}
REDIS_VERSION=${REDIS_VERSION:-latest}

SOURCE=${SOURCE:-user-config}
SMARTHOST_PROXY_PATH=$SMARTHOST_PROXY_PATH
HTPASSWD_FILE=${HTPASSWD_FILE:-/etc/system/config/smarthost-proxy/nginx/htpasswd}

GIT_URL=${GIT_URL:-git.format.hu}
REPO=$REPO

# scheduler settings
CURL_SLEEP_SHORT=${CURL_SLEEP_SHORT:-5}
CURL_RETRIES=${CURL_RETRIES:-360}

SCHEDULER_SERVICEFILE_GENERATE_TEST=${SCHEDULER_SERVICEFILE_GENERATE_TEST:-false}

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

DEBUG=1

# writes debug message if DEBUG variable is set
debug() {
    if [ $DEBUG -eq 1 ]; then
        echo "DEBUG: "$1 $2 $3
    fi
}

add_json_target(){

        local TASK_NAME=$1

        if [ -n "$TASK_NAME" ]; then
            TASK="upgrade-$TASK_NAME"
        fi
        
        install -m 664 -g 65534 /dev/null $SHARED/output/$TASK.json
        echo $JSON_TARGET | base64 -d >$SHARED/output/$TASK.json
}

backup_query_state() {

    echo "backup_query_state"

}

backup_set_service() {

    echo "backup_set_service"

}

backup_set_client() {

    NAME="$1"
    SIZE="$2"
    VPN="$3"
    SSH_PORT="$4"
    SSH_USER="$5"
    SSH_PASSWORD="$6"
    OPERATION="$7"
    VPN_KEY="$8"

    if [ "$OPERATION" == "DELETE" ]; then
        # delete service
        if [ -f "/etc/user/config/services/service-backup-client-$NAME.json" ]; then

            debug "service-backup-client-$NAME.json stop force dns-remove"
            $service_exec service-backup-client-$NAME.json stop force dns-remove
            rm -f /etc/user/config/services/service-backup-client-$NAME.json
            debug "Service backup client $NAME deleted."

        fi

    else

        if [ -z "$SSH_PORT" ] ; then
            SSH_PORT=20022
        fi

        if [ "$VPN" == "true" ]; then
            NETWORK=$NAME
            PORT='"PORTS": [{"SOURCE":"null","DEST":"'$SSH_PORT'","TYPE":"tcp"}],'
        else
            NETWORK="host"
            PORT='"PORTS": [{"SOURCE":"'$SSH_PORT'","DEST":"'$SSH_PORT'","TYPE":"tcp"}],'
        fi

        ADDITIONAL=""
        ADDITIONAL='"EXTRA": "--label logging=promtail_user --label logging_jobname=containers --restart=always", "PRE_START": [], "DEPEND": [], "CMD": ""'
        ENVS='"ENVS": [{"SSH_USER":"'$SSH_USER'"},{"SSH_PORT":"'$SSH_PORT'"},{"SSH_PASSWORD":"'$SSH_PASSWORD'"},{"VPN_CLIENT_KEY":"'$VPN_KEY'"}],'

        echo '{
    "main": {
    "SERVICE_NAME": "'$NAME'"
    },
    "containers": [
    {
    "IMAGE": "alpine:latest",
    "NAME": "'$NAME'-init",
    "UPDATE": "true",
    "MEMORY": "64M",
    "EXTRA": "--rm",
    "VOLUMES":[
        {
        "SOURCE": "USER_DATA",
        "DEST": "/etc/user/data/",
        "TYPE": "rw"
        }
            ],
    "ENTRYPOINT": "sh -c",
    "CMD": "mkdir -p /etc/user/data/backup/clients/'$NAME'/backup && /etc/user/data/backup/clients/'$NAME'/ssh",
    "POST_START": []
    },
    {
    "IMAGE": "safebox/backup-client:latest",
    "NAME": "'$NAME'",
    "UPDATE": "true",
    "MEMORY": "64M",
    "NETWORK": "'$NETWORK'",
    '$ADDITIONAL',
    '$ENVS'
    '$PORT'
    "VOLUMES":[
        { 
        "SOURCE": "/etc/user/data/backup/clients/'$NAME'/backup",
        "DEST": "/backup",
        "TYPE": "rw"
        },
        { 
        "SOURCE": "/etc/user/data/backup/clients/'$NAME'/ssh",
        "DEST": "/home/'$SSH_USER'/",
        "TYPE": "rw"
        }
            ],
    "POST_START": []
        }
    ]
 }' | jq -r . >/etc/user/config/services/service-backup-client-$NAME.json

        debug "service-backup-client-$NAME.json stop force dns-remove"
        $service_exec service-backup-client-$NAME.json start &

    fi

}

backup_challenge_clients() {

    echo "backup_challenge_clients"

}

restore_from_backup() {

    echo "restore_from_backup"

}

create_htpasswd_file() {

    local USER="$1"
    local PASSWD="$2"

    if [ ! -f "$HTPASSWD_FILE" ]; then
        install -m 664 -g 65534 /dev/null $HTPASSWD_FILE
        htpasswd -cb $HTPASSWD_FILE $USER $PASSWD
    fi
}

deploy_additionals() {

    local DIR="$1"
    local NAME="$2"
    local JSON="$(echo "$3" | base64 -d)"

    debug "DEPLOY: $NAME"
    debug "JSON: $JSON"

    if [ ! -d "$SECRET_DIR/$NAME" ]; then
        mkdir -p "$SECRET_DIR/$NAME"
    fi

    # copy json files into service directory
    cp -rv $DIR/$NAME-secret.json $SECRET_DIR/$NAME/$NAME.json

    cp -rv $DIR/*.json $SERVICE_DIR/
    rm $SERVICE_DIR/template.json
    rm $SERVICE_DIR/$NAME-secret.json

    # env variables are named by "key" from the source template
    # for example NEXTCLOUD_DOMAIN, NEXTCLOUD_USERNAME, NEXTCLOUD_PASSWORD have to be set by according to template

    # Loop through each key in the JSON and create a variable
    for key in $(echo "$JSON" | jq -r 'keys[]'); do
        value=$(echo "$JSON" | jq -r --arg k "$key" '.[$k]')
        # eval "$key=$value"
        value=$(echo "$value" | sed 's/\//\\\//g') # escape / character

        # replace variables in secret and domain files
        sed -i "s/#$key/$value/g" $SECRET_DIR/$NAME/$NAME.json
        #sed -i "s/#"$key"/"$value"/g" $SERVICE_DIR/domain-$NAME.json
        sed -i "s/#$key/$value/g" $SERVICE_DIR/*$NAME*.json
    done

    # start service
    debug "$service_exec service-$NAME.json start info"
    $service_exec service-$NAME.json start info &
    PID=$!
}

remove_additionals() {
    local DIR="$1"
    local NAME="$2"

    debug "UNINSTALL: $NAME"

    # delete firewall rules
    FIREWALLS=""
    FIREWALLS="$(ls $SERVICE_DIR/firewall-*.json | grep $NAME)"
    for FIREWALL in $(echo $FIREWALLS); do
        cat $FIREWALL | jq '.containers[] |= (
        if (.ENVS | map(has("OPERATION")) | any) then
            # If any entry has OPERATION key, update it
            .ENVS = [.ENVS[] | if has("OPERATION") then {"OPERATION": "DELETE"} else . end]
        else
            # If no entry has OPERATION key, add new entry
            .ENVS += [{"OPERATION": "DELETE"}]
        end
        )' >$FIREWALL.tmp
        debug "$service_exec $FIREWALL.tmp start info"
        $service_exec $FIREWALL.tmp start info
        rm $FIREWALL.tmp
    done

    # delete domains
    DOMMAINS=""
    DOMAINS="$(ls $SERVICE_DIR/domain-*.json | grep $NAME)"
    for DOMAIN in $(echo $DOMAINS); do
        cat $DOMAIN | jq '.containers[] |= (
        if (.ENVS | map(has("OPERATION")) | any) then
            # If any entry has OPERATION key, update it
            .ENVS = [.ENVS[] | if has("OPERATION") then {"OPERATION": "DELETE"} else . end]
        else
            # If no entry has OPERATION key, add new entry
            .ENVS += [{"OPERATION": "DELETE"}]
        end
        )' >$DOMAIN.tmp
        debug "$service_exec $DOMAIN.tmp start info"
        $service_exec $DOMAIN.tmp start info
        rm $DOMAIN.tmp
    done

    # remove related directories and files
    # get volume destinations
    DESTINATIONS=""
    VOLUMES=""
    DESTINATIONS=$(cat $SERVICE_DIR/service-$NAME.json | jq -r '[.containers[] | select(has("VOLUMES")) | .VOLUMES[] | select(.SHARED != "true") | .SOURCE] | unique[]' | grep $NAME)
    for DESTINATION in $(echo $DESTINATIONS); do
        if [ -d "$DESTINATION" ] || [ -f "$DESTINATION" ]; then
            rm -rf $DESTINATION
            debug "deleted directory or file: $DESTINATION"
        fi
    done

    ENV_FILES=$(cat $SERVICE_DIR/service-$NAME.json | jq -r '[.containers[] | select(has("ENV_FILES")) | .ENV_FILES[]] | unique[]')
    for ENV_FILE in $(echo $ENV_FILES); do
        if [ -f "$ENV_FILE" ]; then
            rm -rf $ENV_FILE
            debug "deleted enviroment file: $ENV_FILE"
        fi
    done

    VOLUMES=$(cat $SERVICE_DIR/service-$NAME.json | jq -r '[.containers[] | select(has("VOLUMES")) | .VOLUMES[] | select(.SHARED != "true") | .SOURCE] | unique[]' | grep -vE 'USER|SYSTEM')

    # stop service
    # force - remove stopped container, docker rm
    debug "$service_exec service-$NAME.json stop force dns-remove"
    $service_exec service-$NAME.json stop force dns-remove

    for VOLUME in $(echo $VOLUMES | grep -vE 'USER|SYSTEM|SHARED'); do
        if [ "$(echo $VOLUME | cut -d '/' -f1)" ]; then
            docker volume rm $VOLUME
            debug "deleted volume: $VOLUME"

        fi
    done

    # remove service files
    rm $SERVICE_DIR/*"-"$NAME.json # service, domain, etc.

}

get_repositories() {

    local REPOS
    local BASE
    local TREES=""
    local REPO

    REPOS=$(jq -r .repositories[] /etc/user/config/repositories.json) # list of repos, delimiter by space
    for REPO in $REPOS; do

        BASE=$(basename $REPO | cut -d '.' -f1)
        if [ ! -d "/tmp/$BASE" ]; then
            GIT_HTTP_CONNECT_TIMEOUT=10 GIT_HTTP_TIMEOUT=30 git clone $REPO /tmp/$BASE >/dev/null
        else
            cd /tmp/$BASE
            GIT_HTTP_CONNECT_TIMEOUT=10 GIT_HTTP_TIMEOUT=30 git pull >/dev/null
        fi
        if [ -f "/tmp/$BASE/applications-tree.json" ]; then
            TREES=$TREES" /tmp/$BASE/applications-tree.json"
        fi
    done

    echo $TREES
}

check_volumes() {

    RET=1
    if [ ! -d "/var/tmp/shared" ]; then
        /usr/bin/docker volume create SHARED
        RET=0
    fi

    if [ ! -d "/etc/system/data/" ]; then
        /usr/bin/docker volume create SYSTEM_DATA
        RET=0
    fi
    if [ ! -d "/etc/system/config/" ]; then
        /usr/bin/docker volume create SYSTEM_CONFIG
        RET=0
    fi
    if [ ! -d "/etc/system/log/" ]; then
        /usr/bin/docker volume create SYSTEM_LOG
        RET=0
    fi
    if [ ! -d "/etc/user/data/" ]; then
        /usr/bin/docker volume create USER_DATA
        RET=0
    fi
    if [ ! -d "/etc/user/config/" ]; then
        /usr/bin/docker volume create USER_CONFIG
        RET=0
    fi
    if [ ! -d "/etc/user/secret/" ]; then
        /usr/bin/docker volume create USER_SECRET
        RET=0
    fi
    echo $RET
}

check_dirs_and_files() {

    RET=0
    if [ ! -d "/var/tmp/shared" ]; then
        mkdir -p /var/tmp/shared
    fi

    if [ ! -d "/var/tmp/shared/input" ]; then
        mkdir -p /var/tmp/shared/input
    fi

    if [ ! -d "/var/tmp/shared/output" ]; then
        mkdir -p /var/tmp/shared/output
    fi
    # Setting file and directory permssion
    chown -R 65534:65534 /var/tmp/shared
    chmod -R g+rws /var/tmp/shared
    setfacl -d -m g:65534:rw /var/tmp/shared

    if [ ! -d "/etc/user/config/services/" ]; then
        mkdir -p /etc/user/config/services/
    fi

    if [ ! -d "/etc/user/config/services/tmp/" ]; then
        mkdir -p /etc/user/config/services/tmp/

        if [[ -f "/etc/user/config/system.json" && -f "/etc/user/config/user.json" ]]; then
            RET=1
        fi
    fi

    if [ ! -d "/etc/system" ]; then
        mkdir -p"/etc/system"
    fi

    if [ ! -d "/etc/user/secret" ]; then
        mkdir -p "/etc/user/secret"
    fi
    echo $RET
}

check_subnets() {

    RET=1
    SUBNETS=$(for ALL in $(/usr/bin/docker network ls | grep bridge | awk '{print $1}'); do /usr/bin/docker network inspect $ALL --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'; done)
    RES=$(echo "$SUBNETS" | grep "172.19.")
    if [ "$RES" != "" ]; then
        for R in $RES; do
            NUMBER=$(echo $R | cut -d '.' -f3)
            if [[ $NUMBER -ge 0 && $NUMBER -le 254 ]]; then
                RET=0
            fi
        done
    fi
    echo $RET
}

check_framework_scheduler_status() {

    ACTUAL_FRAMEWORK_SCHEDULER_NAME=$1

    RET=1
    if [ "$ACTUAL_FRAMEWORK_SCHEDULER_NAME" != "$FRAMEWORK_SCHEDULER_NAME" ]; then
        RET=0
    else
        desired_subnet=$FRAMEWORK_SCHEDULER_NETWORK_SUBNET
        existing_subnets=$(/usr/bin/docker network inspect $(/usr/bin/docker network ls -q) --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')

        # Check if the desired subnet is in the list of existing subnets
        if echo "$existing_subnets" | grep -q "$desired_subnet"; then
            if [ "$(/usr/bin/docker network inspect $FRAMEWORK_SCHEDULER_NETWORK --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')" != "$FRAMEWORK_NETWORK_SUBNET" ]; then
                RET=0
            fi
        else
            RET=0
        fi
    fi

}

add_repository() {
    NEW_REPO="$1"

    if [ ! -f "/etc/user/config/repositories.json" ]; then
        create_repositories_json
    fi
    UPDATED_REPOS=$(cat /etc/user/config/repositories.json | jq '.repositories += ["'$NEW_REPO'"]')
    echo "$UPDATED_REPOS" | jq -r . >/etc/user/config/repositories.json
}

create_repositories_json() {
    {
        echo '
{
	"repositories": [ "https://git.format.hu/safebox/default-applications-tree.git" ]
}
'
    } | jq -r . >/etc/user/config/repositories.json
}

create_system_json() {
    {
        echo '
{
	"NETWORK": {
		"IP_POOL_START": "172.19.0.0",
		"IP_POOL_END": "172.19.254.0",
		"IP_SUBNET": "24"
	}
}
'
    } >/etc/user/config/system.json
}

create_user_json() {
    touch /etc/user/config/user.json
}

create_framework_json() {

    if [ "$DEBUG_MODE" == "TRUE" ]; then
        ENTRYPOINT='"ENTRYPOINT": "sh","CMD": "sleep 86400",'
    else
        ENTRYPOINT=""
    fi

    ADDITIONAL=""
    ADDITIONAL='"EXTRA": "--label logging=promtail_user --label logging_jobname=containers --restart=always", "PRE_START": [], "DEPEND": [], "CMD": ""'
    ENVS='"ENVS": [{"RUN_FORCE": "'$RUN_FORCE'"}, {"DOCKER_REGISTRY_URL": "'$DOCKER_REGISTRY_URL'"}, {"WEBSERVER_PORT": "'$WEBSERVER_PORT'"}],'
    echo '{
  "main": {
    "SERVICE_NAME": "framework"
  },
  "containers": [
    {
      "IMAGE": "'$DOCKER_REGISTRY_URL'/'$FRAMEWORK_SCHEDULER_IMAGE':'$FRAMEWORK_SCHEDULER_VERSION'",
      "NAME": "'$FRAMEWORK_SCHEDULER_NAME'",
      "UPDATE": "true",
      "MEMORY": "256M",
      "NETWORK": "'$FRAMEWORK_SCHEDULER_NETWORK'",
      '$ADDITIONAL',
      '$ENVS'
      '$ENTRYPOINT'
      "VOLUMES":[
        { "SOURCE": "SHARED",
          "DEST": "'$SHARED'",
          "TYPE": "rw"
        },
        { "SOURCE": "SYSTEM_DATA",
          "DEST": "/etc/system/data",
          "TYPE": "rw"
        },
        { "SOURCE": "SYSTEM_CONFIG",
          "DEST": "/etc/system/config",
          "TYPE": "rw"
        },
        { "SOURCE": "SYSTEM_LOG",
          "DEST": "/etc/system/log",
          "TYPE": "rw"
        },
        { "SOURCE": "USER_DATA",
          "DEST": "/etc/user/data",
          "TYPE": "rw"
        },
        { "SOURCE": "USER_CONFIG",
          "DEST": "/etc/user/config",
          "TYPE": "rw"
        },
        { "SOURCE": "USER_SECRET",
          "DEST": "/etc/user/secret",
          "TYPE": "rw"
        },
        { "SOURCE": "/var/run/docker.sock",
          "DEST": "/var/run/docker.sock",
          "TYPE": "rw"
        }
            ],
      "POST_START": []
    },
	{
      "IMAGE": "'$DOCKER_REGISTRY_URL'/'$WEB_IMAGE':'$WEBSERVER_VERSION'",
      "NAME": "'$WEB_SERVER'",
      "UPDATE": "true",
      "MEMORY": "128M",
      "NETWORK": "'$FRAMEWORK_SCHEDULER_NETWORK'",
      '$ADDITIONAL',
      "PORTS":[
        { "SOURCE": "'$WEBSERVER_PORT'",
          "DEST": "80",
          "TYPE": "tcp"
        }
            ],
      "VOLUMES":[
        { "SOURCE": "SHARED",
          "DEST": "'$SHARED'",
          "TYPE": "rw"
        }
            ],
      "POST_START": []
    }
  ]
}
  ' | jq -r . >/etc/user/config/services/service-framework.json
}

check_update() {

    local IMAGE="$1"

    debug "IMAGE: $IMAGE"

    REPOSITORY_URL=$(echo $IMAGE | cut -d '/' -f1)

    # if image repository url doesn't contain dot (safebox)
    if [[ "$(echo "$REPOSITORY_URL" | grep '\.')" == "" ]]; then
        REMOTE_URL="registry.hub.docker.com"
        TEMP_PATH=$IMAGE
        TEMP_IMAGE=$(echo $TEMP_PATH | cut -d ':' -f1)
        TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:{$TEMP_IMAGE}:pull" | jq -r .token)
        TOKEN_HEADER='-H "Authorization: Bearer '$TOKEN'"'
    else
        REMOTE_URL=""
        # -f2- IMAGE can contain subdirectories
        TEMP_PATH=$(echo $IMAGE | cut -d '/' -f2-)
        TOKEN=""
        TOKEN_HEADER=""
    fi

    debug "TEMP PATH: $TEMP_PATH"
    TEMP_IMAGE=$(echo $TEMP_PATH | cut -d ':' -f1)
    TEMP_VERSION=$(echo $TEMP_PATH | cut -d ':' -f2)
    if [ "$TEMP_VERSION" == "$TEMP_IMAGE" ]; then # version is not set
        TEMP_VERSION="latest"
    fi

    REMOTE_URL="https://$REMOTE_URL/v2/$TEMP_IMAGE/manifests/$TEMP_VERSION"
    debug "REMOTE_URL: $REMOTE_URL"

    # Check whether repository url is available
    #CURL_CHECK="curl -m 5 -s -o /dev/null -w "%{http_code}" https://$REPOSITORY_URL/v2/"
    CURL_CHECK='curl -m 5 -s -o /dev/null -I '"$TOKEN_HEADER"' -w "%{http_code}" '"$REMOTE_URL"
    CURL_CHECK_CODE=$(eval $CURL_CHECK)

    # if valid accessible url
    if [[ "$CURL_CHECK_CODE" == "200" ]]; then
        debug "$REMOTE_URL repository accessed successfully"

        #digest=$(curl --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "$REMOTE_URL" | jq -r '.config.digest');
        # Digest for the whole manifest, which includes all architectures.
        CURL_DIGEST='curl -s -I '"$TOKEN_HEADER"' -H "Accept: application/vnd.oci.image.index.v1+json" '"$REMOTE_URL"' | grep -i Docker-Content-Digest | cut -d " " -f2 | tr -d "\r\n"'
        digest=$(eval $CURL_DIGEST)

        #debug "docker images -q --no-trunc $REPOSITORY_URL/$TEMP_IMAGE:$TEMP_VERSION";
        #local_digest=$(docker images -q --no-trunc $REPOSITORY_URL/$TEMP_IMAGE:$TEMP_VERSION)
        debug "docker image inspect $IMAGE --format '{{index .RepoDigests 0}}' | cut -d '@' -f2"
        # Digest for the whole manifest, which includes all architectures.
        local_digest=$(docker image inspect $IMAGE --format '{{index .RepoDigests 0}}' | cut -d '@' -f2)

        debug "REMOTE DIGEST: $digest"
        debug "LOCAL DIGEST: $local_digest"

        if [ "$digest" != "$local_digest" ]; then
            echo "Update available. You can execute update command..."
            UPDATE="1"
            #DOCKER_PULL="docker pull $REPOSITORY_URL/$TEMP_IMAGE:$TEMP_VERSION"
            #eval $DOCKER_PULL
            #STATUS=$?
            #debug "PULL STATUS: $STATUS"
            #if [ $STATUS != 0 ] ; then # Exit status of last task
            #	echo "PULL ERROR: $DOCKER_PULL no any new image accessible in registry $REPOSITORY_URL";
            #else
            #	UPDATE="1";
            #fi
        else
            UPDATE="0"
            echo "Already up to date. Nothing to do."
        fi
    else
        debug "$REMOTE_URL not accessible, http error code: $CURL_CHECK_CODE"

        echo "Force image pull has started without digest check..."
        DOCKER_PULL="/usr/bin/docker pull $IMAGE"
        eval $DOCKER_PULL
        STATUS=$?
        debug "PULL STATUS: $STATUS"
        if [ $STATUS != 0 ]; then # Exit status of last task
            echo "PULL ERROR: $DOCKER_PULL no any new image accessible in registry $REPOSITORY_URL"
        else
            UPDATE="1"
        fi
    fi
}

upgrade_scheduler() {

    # Upgrading framework scheduler
    debug "Upgrading framework scheduler..."
    /usr/bin/docker pull "$DOCKER_REGISTRY_URL/$FRAMEWORK_SCHEDULER_IMAGE:$FRAMEWORK_SCHEDULER_VERSION"

    DOCKER_START="$DOCKER_REGISTRY_URL/$FRAMEWORK_SCHEDULER_IMAGE:$FRAMEWORK_SCHEDULER_VERSION"

    if [ "$DEBUG_MODE" == "true" ]; then
        SET_DEBUG_MODE="--env DEBUG_MODE=true"
    else
        SET_DEBUG_MODE=""
    fi

    FRAMEWORK_SCHEDULER_NAME="$FRAMEWORK_SCHEDULER_NAME-$(head /dev/urandom | tr -dc '0-9' | head -c 6)"

    DOCKER_RUN="/usr/bin/docker run -d \
        -v SHARED:/var/tmp/shared \
	  	-v /var/run/docker.sock:/var/run/docker.sock \
		-v SYSTEM_DATA:/etc/system/data \
		-v SYSTEM_CONFIG:/etc/system/config \
		-v SYSTEM_LOG:/etc/system/log \
		-v USER_DATA:/etc/user/data \
		-v USER_CONFIG:/etc/user/config \
		-v USER_SECRET:/etc/user/secret \
		--restart=always \
        --name $FRAMEWORK_SCHEDULER_NAME \
        $SET_DEBUG_MODE \
	  	--env WEBSERVER_PORT=$WEBSERVER_PORT \
	  	--network $FRAMEWORK_SCHEDULER_NETWORK \
		--env RUN_FORCE=$RUN_FORCE \
		--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
	  $DOCKER_START"
    eval "$DOCKER_RUN"
}

upgrade() {
    local NAME=$1

    if [ "$NAME" == "webserver" ]; then
        debug "$service_exec service-framework.containers.$NAME stop force"
        $service_exec service-framework.containers.$NAME stop force
        debug "$service_exec service-framework.containers.$NAME start info"
        $service_exec service-framework.containers.$NAME start info &
    else

        debug "$service_exec $NAME.json stop force"
        $service_exec $NAME.json stop force
        debug "$service_exec $NAME.json start info"
        $service_exec $NAME.json start info &

    fi

    PID=$!
}

execute_task() {
    TASK="$1"
    B64_JSON="$2"
    DATE=$(date +"%Y%m%d%H%M")

    # Executing task
    TASK_NAME=$(echo $TASK | cut -d ':' -f1)
    if [ "$TASK_NAME" != "check_vpn" ]; then
        debug "TASK: $(echo $TASK_NAME | cut -d ':' -f1)"
    fi

    # checking sytem status
    SYSTEM_STATUS=$(ls /etc/user/config/services/*.json | grep -v service-framework.json)
    if [ "$SYSTEM_STATUS" != "" ]; then
        INSTALL_STATUS="1" # has previous install
    else
        INSTALL_STATUS="2" # new install
    fi

    if [ "$TASK_NAME" == "install" ]; then
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "0" }' | jq -r . | base64 -w0) # install has started
        #redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET"
        install -m 664 -g 65534 /dev/null $SHARED/output/$TASK.json
        echo $JSON_TARGET | base64 -d >$SHARED/output/$TASK.json

        #if [ "$INSTALL_STATUS" == "2" ]; then
        # force install?
        # TODO - start install.sh
        sh /scripts/install.sh "$B64_JSON" "$service_exec" "true" "$GLOBAL_VERSION"
        #fi;
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "request_letsencrypt" ]; then
        DOMAINS=$(echo $B64_JSON | base64 -d | jq -r 'keys[]')
        for DOMAIN in $(echo $DOMAINS); do
            REQUEST=$(echo $B64_JSON | base64 -d | jq -r ".[\"$DOMAIN\"].status")

            if [ "$REQUEST" == "requested" ]; then
                echo "New certificate for $DOMAIN is requested."
                echo "Modifying $DOMAIN_FILE.json for $DOMAIN"
                jq '.containers[0].ENVS |= map(if has("OPERATION") then .OPERATION = "MODIFY" else . end) | \
                .containers[0].ENVS |= map(if has("DOMAIN") then .DOMAIN = "'$DOMAIN'" else . end)' \
                /etc/user/config/services/$DOMAIN_FILE.json > /tmp/$DOMAIN_FILE.json && \
                mv /tmp/$DOMAIN_FILE.json /etc/user/config/services/$DOMAIN_FILE.json
                debug "$service_exec $DOMAIN_FILE.json start info"
                $service_exec $DOMAIN_FILE.json start info &
            fi
        done
        JSON_TARGET=$B64_JSON

    elif [ "$TASK_NAME" == "system" ]; then
        #SYSTEM_LIST="core-dns.json cron.json domain-local-backend.json firewall-letsencrypt.json firewall-local-backend.json firewall-localloadbalancer-dns.json firewall-localloadbalancer-to-smarthostbackend.json firewall-smarthost-backend-dns.json firewall-smarthost-loadbalancer-dns.json firewall-smarthost-to-backend.json firewall-smarthostloadbalancer-from-publicbackend.json letsencrypt.json local-backend.json local-proxy.json service-framework.json smarthost-proxy-scheduler.json smarthost-proxy.json"
        SYSTEM_LIST="core-dns.json cron.json letsencrypt.json local-proxy.json service-framework.json smarthost-proxy-scheduler.json smarthost-proxy.json"
        INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json)
        SERVICES=""
        for SERVICE in $(echo $INSTALLED_SERVICES); do
            X=$(echo $SYSTEM_LIST | grep -w "$(basename $SERVICE)")
            if [ "$X" != "" ]; then # is is a system file
                CONTENT=$(cat $SERVICE | base64 -w0)
                if [ "$SERVICES" != "" ]; then
                    SEP=","
                else
                    SEP=""
                fi

                SERVICE_NAME=$(cat $SERVICE | jq -r .main.SERVICE_NAME)
                CONTAINER_NAMES=$(cat $SERVICE | jq -r .containers[].NAME)

                CON_IDS=""
                for CONTAINER_NAME in $CONTAINER_NAMES; do
                    CON_ID=$(docker ps -a --format '{{.ID}} {{.Names}}' | grep -E " $CONTAINER_NAME(-|$)" | awk '{print $1}')
                    CON_IDS=$CON_IDS" "$CON_ID

                done
                CON_IDS=$(echo "$CON_IDS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

                CONTAINERS=""
                for CON_ID in $CON_IDS; do
                    if [ "$CONTAINERS" != "" ]; then
                        CONTAINERS=$CONTAINERS"|"
                    fi
                    CONTAINERS="$CONTAINERS"$(docker ps -a --format "{{.Names}}#{{.Image}}#{{.Status}}" --filter "id=$CON_ID")
                done

                #RESULT=$(echo "$CONTAINERS" | base64 -w0);
                SERVICES=$SERVICES$SEP'"'$SERVICE_NAME'": {"content": "'$CONTENT'", "running": "'$CONTAINERS'"}'
            fi
        done

        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "services" ]; then
        SYSTEM_LIST="core-dns.json cron.json letsencrypt.json local-proxy.json service-framework.json smarthost-proxy-scheduler.json smarthost-proxy.json"
        INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json)
        SERVICES=""
        for SERVICE in $(echo $INSTALLED_SERVICES); do
            X=$(echo $SYSTEM_LIST | grep -w "$(basename $SERVICE)")

            if [ "$X" == "" ]; then # not a system file
                CONTENT=$(cat $SERVICE | base64 -w0)
                if [ "$SERVICES" != "" ]; then
                    SEP=","
                else
                    SEP=""
                fi

                SERVICE_NAME=$(cat $SERVICE | jq -r .main.SERVICE_NAME)
                if [ "$SERVICE_NAME" != "firewalls" ]; then
                    CONTAINER_NAMES=$(cat $SERVICE | jq -r .containers[].NAME)

                    CON_IDS=""
                    for CONTAINER_NAME in $CONTAINER_NAMES; do
                        CON_ID=$(docker ps -a --format '{{.ID}} {{.Names}}' | grep -E " $CONTAINER_NAME(-|$)" | awk '{print $1}')
                        CON_IDS=$CON_IDS" "$CON_ID

                    done
                    CON_IDS=$(echo "$CON_IDS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

                    CONTAINERS=""
                    for CON_ID in $CON_IDS; do
                        if [ "$CONTAINERS" != "" ]; then
                            CONTAINERS=$CONTAINERS"|"
                        fi
                        CONTAINERS="$CONTAINERS"$(docker ps -a --format "{{.Names}}#{{.Image}}#{{.Status}}" --filter "id=$CON_ID")
                    done

                    #RESULT=$(echo "$CONTAINERS" | base64 -w0);
                    SERVICES=$SERVICES$SEP'"'$SERVICE_NAME'": {"content": "'$CONTENT'", "running": "'$CONTAINERS'"}'
                fi
            fi
        done

        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "updates" ]; then
        INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json)
        SERVICES=""
        for SERVICE in $(echo $INSTALLED_SERVICES); do
            if [ "$SERVICES" != "" ]; then
                SEP=","
            else
                SEP=""
            fi

            SERVICE_NAME=$(cat $SERVICE | jq -r .main.SERVICE_NAME)
            if [ "$SERVICE_NAME" != "firewalls" ]; then
                CONTAINER_NAMES=$(cat $SERVICE | jq -r .containers[].NAME)
                UPDATE_CONTAINERS=""
                UPTODATE_CONTAINERS=""
                ERROR_CONTAINERS=""
                for CONTAINER_NAME in $CONTAINER_NAMES; do
                    #IMAGE=$(cat $SERVICE | jq -rc '.containers[] | select(.NAME=="'$CONTAINER_NAME'") | .IMAGE');
                    IMAGE=$(cat $SERVICE | jq -rc --arg NAME "$CONTAINER_NAME" '.containers[] | select(.NAME==$NAME) | .IMAGE')
                    if [ "$IMAGE" != "" ]; then
                        UPDATE=""
                        check_update "$IMAGE"
                        if [ "$UPDATE" == "1" ]; then
                            UPDATE_CONTAINERS="$UPDATE_CONTAINERS $CONTAINER_NAME"
                        elif [ "$UPDATE" == "0" ]; then
                            UPTODATE_CONTAINERS="$UPTODATE_CONTAINERS $CONTAINER_NAME"
                        else
                            ERROR_CONTAINERS="$UPTODATE_CONTAINERS $CONTAINER_NAME"
                        fi
                    fi
                done
                #RESULT=$(echo "$CONTAINERS" | base64 -w0);
                SERVICES=$SERVICES$SEP'"'$SERVICE_NAME'": {"uptodate": "'$UPTODATE_CONTAINERS'", "update": "'$UPDATE_CONTAINERS'", "error": "'$ERROR_CONTAINERS'"}'
            fi
        done

        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "deployments" ]; then
        DEPLOYMENTS=""
        TREES=$(get_repositories)
        for TREE in "$TREES"; do
            APPS=$(jq -rc '.apps[]' $TREE)
            #for APP in "$APPS"; do #space problem
            while IFS= read -r APP; do
                APP_NAME=$(echo "$APP" | jq -r '.name')
                APP_SUBTITLE="$(echo "$APP" | jq -r '.subtitle')"
                APP_VERSION=$(echo "$APP" | jq -r '.version')
                APP_ICON=$(echo "$APP" | jq -r '.icon')
                if [ "$DEPLOYMENTS" != "" ]; then
                    SEP=","
                else
                    SEP=""
                fi
                DEPLOYMENTS="$DEPLOYMENTS"$SEP'"'$APP_NAME'":{"subtitle":"'"$APP_SUBTITLE"'","version":"'"$APP_VERSION"'","icon":"'"$APP_ICON"'"}'
            done < <(echo "$APPS") # preserve DEPLOYMENTS variable
        done
        if [ "$DEPLOYMENTS" == "" ]; then
            DEPLOYMENTS='"deployments": "NONE"'
        fi

        INSTALLED_SERVICES=$(ls /etc/user/config/services/service-*.json)
        SERVICES=""
        for SERVICE in $(echo $INSTALLED_SERVICES); do
            if [ "$(basename $SERVICE)" != "service-framework.json" ]; then # NOT system file
                CONTENT=$(cat $SERVICE | base64 -w0)
                if [ "$SERVICES" != "" ]; then
                    SEP=","
                else
                    SEP=""
                fi
                SERVICES=$SERVICES$SEP'"'$(cat $SERVICE | jq -r .main.SERVICE_NAME)'": "'$CONTENT'"'
            fi
        done
        if [ "$SERVICES" == "" ]; then
            SERVICES='"services": "NONE"'
        fi

        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "DEPLOYMENTS": {'$DEPLOYMENTS'}, "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "deployment" ]; then
        JSON="$(echo $B64_JSON | base64 -d)"
        DEPLOY_NAME=$(echo "$JSON" | jq -r .NAME | awk '{print tolower($0)}')
        DEPLOY_ACTION=$(echo "$JSON" | jq -r .ACTION)
        TREES=$(get_repositories)
        debug "$JSON"

        for TREE in $TREES; do
            APPS=$(jq -rc '.apps[]' $TREE)
            #for APP in $APPS; do
            while IFS= read -r APP; do
                APP_NAME=$(echo "$APP" | jq -r '.name' | awk '{print tolower($0)}')
                APP_SUBTITLE=$(echo "$APP" | jq -r '.subtitle')
                APP_VERSION=$(echo "$APP" | jq -r '.version')
                APP_DIR=$(dirname $TREE)"/"$APP_NAME
                if [ "$APP_NAME" == "$DEPLOY_NAME" ]; then
                    if [ "$DEPLOY_ACTION" == "ask" ]; then
                        APP_TEMPLATE=$APP_DIR"/template.json"
                        TEMPLATE=$(cat $APP_TEMPLATE | base64 -w0)
                        debug "$APP_TEMPLATE"
                        JSON_TARGET=$(echo '{"DATE":"'$DATE'","STATUS": "0","TEMPLATE":"'$TEMPLATE'"}' | jq -r . | base64 -w0)
                    elif [ "$DEPLOY_ACTION" == "reinstall" ]; then
                        APP_TEMPLATE=$APP_DIR"/template.json"
                        TEMPLATE=$(cat $APP_TEMPLATE)
                        for LINE in $(cat $SERVICE_DIR/service-$DEPLOY_NAME.json | jq -rc '.containers[].ENVS[] | to_entries[]' 2>/dev/null); do
                            KEY=$(echo $LINE | jq -r .key)
                            VALUE=$(echo $LINE | jq -r .value)
                            debug "$KEY: $VALUE"
                            # write ENV value from service files to template value by key name
                            #TEMPLATE=$(echo "$TEMPLATE" | jq -r '.fields |= map(.value = "'$VALUE'")')
                            TEMPLATE=$(echo "$TEMPLATE" | jq -r '.fields |= map(if .key == "'$KEY'" then .value = "'$VALUE'" else . end)')
                        done
                        # write ENV value from domain file to template value by key name
                        for LINE in $(cat $SERVICE_DIR/domain-$DEPLOY_NAME.json | jq -rc '.containers[].ENVS[] | to_entries[]' 2>/dev/null); do
                            KEY=$(echo $LINE | jq -r .key)
                            VALUE=$(echo $LINE | jq -r .value)
                            debug "$KEY: $VALUE"
                            TEMPLATE=$(echo "$TEMPLATE" | jq -r '.fields |= map(if .key == "'$KEY'" then .value = "'$VALUE'" else . end)')
                        done
                        # write ENV value from secret file to template value by key name
                        for LINE in $(cat $SECRET_DIR/$DEPLOY_NAME/$DEPLOY_NAME.json | jq -rc '.[] | to_entries[]' 2>/dev/null); do
                            KEY=$(echo $LINE | jq -r .key)
                            VALUE=$(echo $LINE | jq -r .value)
                            debug "$KEY: $VALUE"
                            TEMPLATE=$(echo "$TEMPLATE" | jq -r '.fields |= map(if .key == "'$KEY'" then .value = "'$VALUE'" else . end)')
                        done
                        #echo $TEMPLATE;

                        TEMPLATE=$(echo "$TEMPLATE" | base64 -w0)
                        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "0", "TEMPLATE": "'$TEMPLATE'" }' | jq -r . | base64 -w0)

                    elif [ "$DEPLOY_ACTION" == "deploy" ]; then
                        JSON_TARGET=""
                        #JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "1" }' | jq -r . | base64 -w0) # deployment has started
                        #redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET "$DEPLOY_ACTION-$DEPLOY_NAME" "$JSON_TARGET"                # web_in

                        DEPLOY_PAYLOAD=$(echo "$JSON" | jq -r .PAYLOAD) # base64 list of key-value pairs in JSON
                        deploy_additionals "$APP_DIR" "$DEPLOY_NAME" "$DEPLOY_PAYLOAD"
                        sh /scripts/check_pid.sh "$PID" "$SHARED" "$DEPLOY_ACTION-$DEPLOY_NAME" "$DATE" "$DEBUG" &
                    elif [ "$DEPLOY_ACTION" == "redeploy" ]; then
                        JSON_TARGET=""
                        remove_additionals "$APP_DIR" "$DEPLOY_NAME"

                        DEPLOY_PAYLOAD=$(echo "$JSON" | jq -r .PAYLOAD) # base64 list of key-value pairs in JSON
                        deploy_additionals "$APP_DIR" "$DEPLOY_NAME" "$DEPLOY_PAYLOAD"
                        sh /scripts/check_pid.sh "$PID" "$SHARED" "deploy-$DEPLOY_NAME" "$DATE" "$DEBUG" &

                    elif [ "$DEPLOY_ACTION" == "edit" ]; then
                        JSON_TARGET=""
                        DEPLOY_PAYLOAD=$(echo "$JSON" | jq -r .PAYLOAD) # base64 list of key-value pairs in JSON

                        # stop service before edit
                        debug "$service_exec service-$DEPLOY_NAME.json stop force"
                        $service_exec service-$DEPLOY_NAME.json stop force

                        deploy_additionals "$APP_DIR" "$DEPLOY_NAME" "$DEPLOY_PAYLOAD"
                        sh /scripts/check_pid.sh "$PID" "$SHARED" "deploy-$DEPLOY_NAME" "$DATE" "$DEBUG" &

                    elif [ "$DEPLOY_ACTION" == "uninstall" ]; then
                        remove_additionals "$APP_DIR" "$DEPLOY_NAME"
                        # uninstall has finished
                        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "2" }' | jq -r . | base64 -w0)
                        debug "JSON_TARGET: $JSON_TARGET"
                        echo $JSON_TARGET | base64 -d >$SHARED/output/"uninstall-"$DEPLOY_NAME.json
                        JSON_TARGET=""
                    fi
                fi
            done < <(echo "$APPS") # preserve variables
        done

    elif [ "$TASK_NAME" == "repositories" ]; then
        if [ ! -f "/etc/user/config/repositories.json" ]; then
            create_repositories_json
        fi
        REPOS=$(cat /etc/user/config/repositories.json)
        if [ "$REPOS" != "" ]; then
            EXISTS="1"
            REPOS=$(echo "$REPOS" | base64 -w0)
        else
            EXISTS="0"
            REPOS=""
        fi
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "EXISTS": "'$EXISTS'", "REPOSITORIES": "'$REPOS'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "add_repository" ]; then
        JSON="$(echo $B64_JSON | base64 -d)"
        NEW_REPO=$(echo "$JSON" | jq -r .NEW_REPO)
        add_repository "$NEW_REPO"
        JSON_TARGET=""

    elif [ "$TASK_NAME" == "check_vpn" ]; then

        VPN_STATUS="0"
        VPN_RESULT=""
        CONTAINERS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep -w wireguardproxy)
        if [ "$CONTAINERS" != "" ]; then
            UP=$(echo $CONTAINERS | grep -w 'Up')
            if [ "$UP" != "" ]; then
                VPN_STATUS="2"
            else
                VPN_STATUS="1"
            fi
            VPN_RESULT=$(echo "$CONTAINERS" | base64 -w0)
        fi
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "'$VPN_STATUS'", "RESULT": "'$VPN_RESULT'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "save_vpn" ]; then

        VPN_PROXY_REPO="wireguard-proxy-client"
        if [ ! -d "/tmp/$VPN_PROXY_REPO" ]; then
            git clone https://git.format.hu/safebox/$VPN_PROXY_REPO.git /tmp/$VPN_PROXY_REPO >/dev/null
        else
            cd /tmp/$VPN_PROXY_REPO
            git pull >/dev/null
        fi

        cp -av /tmp/$VPN_PROXY_REPO/*.json $SERVICE_DIR/

        VPN_VOLUMES=$(jq -r .containers[0].VOLUMES[0].SOURCE $SERVICE_DIR/vpn-proxy.json)
        VOLUME=$(dirname $VPN_VOLUMES)
        mkdir -p $VOLUME

        # install vpn only
        sh /scripts/install.sh "$B64_JSON" "$service_exec" "vpn" "$GLOBAL_VERSION"

        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "'$VPN_STATUS'", "RESULT": "'$VPN_RESULT'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "containers" ]; then # not in use
        CONTAINERS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep -v framework-scheduler)
        RESULT=$(echo "$CONTAINERS" | base64 -w0)
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "RESULT": "'$RESULT'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "backup" ]; then

        TASK_TYPE=$(echo $B64_JSON | base64 -d | jq -r '.TASK_TYPE)')

        if [ "$TASK_TYPE" == "backup_query_state" ]; then
            echo "task type is backup_query_state"

        elif [ "$TASK_TYPE" == "backup_set_service" ]; then
            echo "task type is backup_set_service"

        elif [ "$TASK_TYPE" == "backup_set_client" ]; then
            
            NAME="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_NAME')"
            SIZE="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_SIZE')"
            VPN="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_VPN')"
            SSH_PORT="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_SSH_PORT')"
            SSH_USER="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_SSH_USER')"
            SSH_PASSWORD="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_SSH_PASSWORD')"
            OPERATION="$(echo $B64_JSON | base64 -d | jq -r '.BACKUP_CLIENT_OPERATION')"
            debug "task type is backup_set_client for $NAME"
            debug "   size: $SIZE"
            debug "   vpn: $VPN"
            debug "   ssh_port: $SSH_PORT"
            debug "   ssh_user: $SSH_USER"
            debug "   ssh_password: $SSH_PASSWORD"
            debug "   operation: $OPERATION"

            backup_set_client "$NAME" "$SIZE" "$VPN" "$SSH_PORT" "$SSH_USER" "$SSH_PASSWORD" "$OPERATION"

        elif [ "$TASK_TYPE" == "backup_challenge_clients" ]; then
            echo "task type is backup_challenge_clients"

        elif [ "$TASK_TYPE" == "restore_from_backup" ]; then
            echo "task type is restore_from_backup"

        else
            echo "Unknown task type: $TASK_TYPE"
        fi

        RESULT=$(echo "$CONTAINERS" | base64 -w0)
        JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "RESULT": "'$RESULT'" }' | jq -r . | base64 -w0)

    elif [ "$TASK_NAME" == "upgrade" ]; then
        JSON="$(echo $B64_JSON | base64 -d)"
        NAME=$(echo "$JSON" | jq -r .NAME | awk '{print tolower($0)}')
        if [ "$NAME" == "framework" ]; then
            JSON_TARGET=$(echo '{"DATE":"'$DATE'","INSTALL_STATUS":0}' | jq -r . | base64 -w0)
            add_json_target $NAME
            echo "Upgrading service: webserver"
            upgrade webserver

            echo "Upgrading framework scheduler..."
            echo "Cleaning temporary files..."
            
            rm -rf /var/tmp/shared/input/*
            rm -rf /var/tmp/shared/output/*

            upgrade_scheduler
            echo "Removing old framework scheduler container..."
            JSON_TARGET=$(echo '{"DATE":"'$DATE'","INSTALL_STATUS":1}' | jq -r . | base64 -w0)
            add_json_target $NAME
            sleep 1
            /usr/bin/docker rm -f $HOSTNAME

            #CONTAINERS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep -E 'framework-scheduler|webserver')
        else
            echo "Upgrading service: $NAME"
            upgrade "$NAME"
            #CONTAINERS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep -w "$NAME")
        fi
        #RESULT=$(echo "$CONTAINERS" | base64 -w0)
        sh /scripts/check_pid.sh "$PID" "$SHARED" "$TASK_NAME-$NAME" "$DATE" "$DEBUG" &
    fi

    if [ "$TASK_NAME" != "check_vpn" ]; then
        debug "JSON_TARGET: $JSON_TARGET"
    fi

    if [ "$JSON_TARGET" != "" ]; then
        add_json_target
    fi

}

check_running() {

    DOCKERD_STATUS="0"

    ### From Redis
    # bridge check
    BRIDGE_NUM=$($SUDO_CMD docker network ls | grep bridge | awk '{print $2":"$3}' | sort | uniq | wc -l)

    CONTAINER_NUM=$($SUDO_CMD docker ps -a | wc -l)

    if [ "$BRIDGE_NUM" != "1" ] && [ "$CONTAINER_NUM" != "1" ]; then

        echo "There are existing containers and/or networks."
        echo "Please select from the following options (1/2/3):"

        echo "1 - Delete all existing containers and networks before installation"
        echo "2 - Stop the installation process"
        echo "3 - Just continue on my own risk"

        read -r ANSWER

        if [ "$ANSWER" == "1" ]; then
            echo "1 - Removing exising containers and networks"
            # delete and continue
            $SUDO_CMD docker stop $($SUDO_CMD docker ps | grep Up | awk '{print $1}')
            $SUDO_CMD docker system prune -a

        elif [ "$ANSWER" == "3" ]; then
            echo "3 - You have chosen to continue installation process."

        else # default: 2 - stop installastion
            echo "2 - Installation process was stopped"
            exit
        fi

    fi
    # visszairni redis - ha redisbol minden 1, akkor manager mode
}

check_redis_availability() {
    REDIS_SERVER="$1"
    REDIS_PORT="$2"
    CURL_RETRIES="$3"
    CURL_SLEEP_SHORT="$4"

    for retries in $(seq 0 "$((CURL_RETRIES + 1))"); do
        if [ "$retries" -le "$CURL_RETRIES" ]; then
            CHECK_REDIS_SERVER="redis-cli -h '$REDIS_SERVER' -p '$REDIS_PORT' PING"
            REDIS_RESPONSE="$(eval "$CHECK_REDIS_SERVER")"

            # echo "$REDIS_SERVER server's reply to PING: $REDIS_RESPONSE"

            if [ "$REDIS_RESPONSE" = "PONG" ]; then
                echo "Connected to $REDIS_SERVER:$REDIS_PORT"
                break
            else
                sleep "$CURL_SLEEP_SHORT"
            fi
        else
            echo "Couldn't reach server at $REDIS_SERVER:$REDIS_PORT after [$CURL_RETRIES] retries, exiting."
            exit 1
        fi
    done
}

### SYSTEM INITIALIZATION ###
## Start prevously deployed firewall rules depend on framework scheduler startup at first time

if [ -d /etc/user/config/services ]; then
    cd /etc/user/config/services
    for FIREWALL in $(ls firewall*.json); do
        $service_exec $FIREWALL start &
    done
fi

SN=$(check_subnets)
if [ "$SN" != "1" ]; then
    echo "Desired network subnet not available running ahead is your own risk"
    if [ "$RUN_FORCE" != "true" ]; then
        echo "Desired network subnet not available, exiting"
        exit
    fi
fi
STATUS=$(check_framework_scheduler_status $HOSTNAME)
if [ "$STATUS" != "1" ]; then
    /usr/bin/docker network create $FRAMEWORK_SCHEDULER_NETWORK --subnet $FRAMEWORK_SCHEDULER_NETWORK_SUBNET
fi

VOL=$(check_volumes)
if [ "$VOL" != "1" ]; then
    upgrade_scheduler
    /usr/bin/docker rm -f $HOSTNAME
fi

DF=$(check_dirs_and_files)
if [ "$DF" != "1" ]; then
    create_system_json
    create_user_json
    create_framework_json
fi

#RS=$(docker ps | grep redis-server)
WS=$(/usr/bin/docker ps | grep -o webserver)

if [ "$WS" == "" ]; then
    # START SERVICES
    echo "Starting webserver"
    $service_exec service-framework.containers.webserver start &

fi

# STARTING SCHEDULER PROCESSES
# Initial parameters
DATE=$(date +%F-%H-%M-%S)

# Set env variables
DIR=$SHARED/input

# Triggers by certificate or domain config changes

unset IFS

inotifywait --exclude "\.(swp|tmp)" -m -e CREATE,CLOSE_WRITE,DELETE,MOVED_TO -r $DIR |
    while read dir op file; do
        if [ "${op}" == "CLOSE_WRITE,CLOSE" ]; then
            if [ "$file" != "check_vpn.json" ]; then
                echo "new file created: $file"
            fi
            B64_JSON=$(cat $DIR/$file | base64 -w0)
            TASK=$(echo $file | cut -d '.' -f1)
            execute_task "$TASK" "$B64_JSON"
            rm -f $dir/$file
        fi
    done

# while true; do

#     TASKS=""

#     # GET DEPLOYMENT IDs FROM generate key
#     #TASKS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS web_in)
#     TASK=$(read $SHARED/output/*)
#     if [[ "$TASKS" != "0" && "$TASKS" != "" ]]; then

#         # PROCESSING TASK
#         for TASK in $(echo $TASKS); do

#             ### READ TASKS FROM REDIS
#             B64_JSON=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT GET $TASK)

#             JSON_TARGET=$(echo $B64_JSON | base64 -d | jq -rc .'STATUS="0"' | base64 -w0)
#             redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET"

#             execute_task "$TASK" "$B64_JSON"

#             # MOVE TASK from web_in into web_out
#             redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM web_in $TASK
#             redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD web_out $TASK
#             echo $JSON_TARGET | base64 -d > $SHARED/output/$TASK.json

#         done
#     fi

#     sleep 1
# done
