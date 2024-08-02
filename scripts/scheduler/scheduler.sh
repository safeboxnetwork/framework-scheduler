#! /bin/sh

cd /scripts

DOCKER_REGISTRY_URL=${DOCKER_REGISTRY_URL:-registry.format.hu}
USER_INIT_PATH=$USER_INIT_PATH

FRAMEWORK_SCHEDULER_IMAGE=${FRAMEWORK_SCHEDULER_IMAGE:-framework-scheduler}
FRAMEWORK_SCHEDULER_NAME=${FRAMEWORK_SCHEDULER_NAME:-framework-scheduler}
FRAMEWORK_SCHEDULER_NETWORK=${FRAMEWORK_SCHEDULER_NETWORK:-framework-network}
FRAMEWORK_SCHEDULER_NETWORK_SUBNET=${FRAMEWORK_SCHEDULER_NETWORK_SUBNET:-"172.19.255.0/24"}
FRAMEWORK_SCHEDULER_VERSION=${FRAMEWORK_SCHEDULER_VERSION:-latest}

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


GIT_URL=$GIT_URL
TOKEN=$TOKEN
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

SETUP_VERSION="1.0.1"

# $DNS_PATH \
#$CA_FILE \
DNS_DIR="/etc/system/data/dns"
DNS="--env DNS_DIR=$DNS_DIR"
DNS_PATH="--volume $DNS_DIR:/etc/system/data/dns:rw"
HOST_FILE=$DNS_DIR"/hosts.local"
mkdir -p $DNS_DIR
touch $HOST_FILE;

CA_PATH=/etc/system/data/ssl/certs
CA="--env CA_PATH=$CA_PATH"
CA_FILE="--volume $CA_PATH:$CA_PATH:ro"
mkdir -p $CA_PATH

VOLUME_MOUNTS="-v SYSTEM_DATA:/etc/system/data -v USER_CONFIG:/etc/user/config:rw";

service_exec="/usr/bin/docker run --rm \
$DNS \
$CA \
-w /etc/user/config/services/ \
$VOLUME_MOUNTS \
-v /var/run/docker.sock:/var/run/docker.sock \
--env VOLUME_MOUNTS="$(echo $VOLUME_MOUNTS | base64 -w0)" \
--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
--env SETUP_VERSION=$SETUP_VERSION \
--env HOST_FILE=$HOST_FILE \
$DOCKER_REGISTRY_URL$SETUP:$SETUP_VERSION"


check_status() {

  # checking sytem status
  RET=0;
  DATE=$( date +"%Y%m%d%H%M")
  TASK="system-status:$DATE"
  SYSTEM_STATUS=$(ls /etc/user/config/services/*.json |grep -v service-framework.json)
        INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json );
        SERVICES="";
        for SERVICE in $(echo $INSTALLED_SERVICES); do
      	  CONTENT=$(cat $SERVICE | base64 -w0);
      	  if [ "$SERVICES" != "" ]; then
      		  SERVICES=","$SERVICES;
        	  fi;
      	  SERVICES=$SERVICES'"'$(cat $SERVICE | jq -r .main.SERVICE_NAME)'": "'$CONTENT'"';
        done
  if [ "$SYSTEM_STATUS" != "" ]; then
          STATUS="1";
  else
          STATUS="2";
  fi
  echo '{ "STATUS": "'$STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }';

  JSON_TARGET=$(echo '{ "STATUS": "'$STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0);

 

 redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";
 redis-cli -h $REDIS_SERVER -p $REDIS_PORT sadd shceduler_in "$TASK";
 RET="";
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

while true; do 

      TASKS=""

      # GET DEPLOYMENT IDs FROM generate key
      TASKS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS scheduler_out)
      if [[ "$TASKS" != "0" && "$TASKS" != "" ]]; then

         #   # PROCESSING TASK
         #   for TASK in $(echo $TASKS); do

         #         ### READ TASKS FROM REDIS
         #         JSON=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT GET $TASK | base64 -d)

         #         JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="0"' | base64 -w0);
         #         redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";

         #         execute_task $TASK $JSON &
         #         
         #         # MOVE TASK from generate into generated
         #         redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM web_in $TASK
         #         redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD web_out $TASK

         #   done
      fi
      
      if [[ "$RET" == "" ]]; then
      		check_status
      fi
      
      sleep 1
done
