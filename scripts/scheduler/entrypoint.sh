#! /bin/sh

cd /scripts

DOCKER_REGISTRY_URL=${DOCKER_REGISTRY_URL:-registry.format.hu}
USER_INIT_PATH=$USER_INIT_PATH

FRAMEWORK_SCHEDULER_IMAGE=${FRAMEWORK_SCHEDULER_IMAGE:-framework-scheduler}
FRAMEWORK_SCHEDULER_NAME=${FRAMEWORK_SCHEDULER_NAME:-framework-scheduler}
FRAMEWORK_SCHEDULER_NETWORK=${FRAMEWORK_SCHEDULER_NETWORK:-framework-network}
FRAMEWORK_NETWORK_SUBNET=${FRAMEWORK_NETWORK_SUBNET:-"172.18.255.0/24"}

WEB_SERVER=${WEB_SERVER:-webserver}
WEB_IMAGE=${WEB_IMAGE:-web-installer}
WEBSERVER_PORT=${WEBSERVER_PORT:-8080}
WEBSERVER_VERSION=${WEBSERVER_VERSION:-latest}
REDIS_SERVER=${REDIS_SERVER:-redis}
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

DNS_DIR="/etc/system/data/dns"
DNS="--env DNS_DIR=$DNS_DIR"
DNS_PATH="--volume $DNS_DIR:/etc/dns:rw"

CA_PATH=/etc/system/data/ssl/certs
CA="--env CA_PATH=$CA_PATH"
CA_FILE="--volume $CA_PATH:$CA_PATH:ro"

service_exec="docker run --rm \
$DNS $DNS_PATH \
$CA $CA_FILE \
-w /etc/user/config/services/ \
-v SYSTEM_DATA:/etc/system/data \
-v USER_CONFIG:/etc/user/config:rw \
-v /var/run/docker.sock:/var/run/docker.sock \
--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
$DOCKER_REGISTRY_URL$SETUP"



check_volumes(){

	RET=1;
	if [ ! -d "/etc/system/data/" ]; then
		docker volume create SYSTEM_DATA;
		RET=0;
	fi
	if [ ! -d "/etc/user/data/" ]; then
		docker volume create USER_DATA;
		RET=0;
	fi;
	if [ ! -d "/etc/user/config/" ]; then
		docker volume create USER_CONFIG;
		RET=0;
	fi;
}

check_dirs_and_files(){

	if [ ! -d "/etc/user/config/services/" ]; then
		mkdir /etc/user/config/services/
	fi;

	if [ ! -d "/etc/user/config/services/tmp/" ]; then
		mkdir /etc/user/config/services/tmp/

		if [[ -f "/etc/user/config/system.json" && -f "/etc/user/config/user.json" ]]; then
			RET=1;
		fi;
	fi;

	echo $RET;
}

check_subnets(){

	SUBNETS=$(for ALL in $(docker network ls | grep bridge | awk '{print $1}') ; do docker network inspect $ALL --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' ; done)

	RES=$(echo "$SUBNETS" | grep "172.19.");
	if [ "$RES" != "" ]; then
		for R in $RES ; do
			NUMBER=$(echo $R | cut -d '.' -f3);
			if [[ $NUMBER > 0 && $NUMBER < 255 ]]; then
				echo $NUMBER;
				echo "TODO"
			fi;
		done;
	fi;
}

check_framework_scheduler_status(){

      ACTUAL_FRAMEWORK_SCHEDULER_NAME=$1;

      if "$ACTUAL_FRAMEWORK_SCHEDULER_NAME" == "$FRAMEWORK_SCHEDULER_NAME"; then
            echo "Scheduler name not correct, not needed to restart is with the correct name";
      else
            FRAMEWORK_NAME=0;
      fi


    if [ "$(docker network inspect $FRAMEWORK_SCHEDULER_NETWORK --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')" == "$FRAMEWORK_NETWORK_SUBNET" ]; then
	  echo "Network $FRAMEWORK_SCHEDULER_NETWORK is available with the correct subnet, not needed to restart the scheduler"
    else
	  check_framework_subnet_availabity
	  FRAMEWORK_SUBNET=0;
    fi


      #echo '{"FRAMEWORK_NAME": "$FRAMEWORK_NAME", "FRAMEWORK_NETWORK": "$FRAMEWORK_NETWORK"}'
}


check_framework_subnet_availabity() {
            
            # Define the subnet you want to check
            desired_subnet=$FRAMEWORK_NETWORK_SUBNET
            existing_subnets=$(docker network inspect $(docker network ls -q) --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')

            # Check if the desired subnet is in the list of existing subnets
            if echo "$existing_subnets" | grep -q "$desired_subnet"; then
                  echo "Subnet $desired_subnet is not available for creation. Need to find another network"
            else
                  echo "Subnet $desired_subnet is available for creation."
            fi
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

start_redis () {

      /usr/bin/docker run -d --name $REDIS_SERVER $REDIS_IMAGE:$REDIS_VERSION
    
}

start_webserver () {

      /usr/bin/docker run -d -p $WEBSERVER_PORT:80/tcp --name $WEB_SERVER $DOCKER_REGISTRY_URL/$WEB_IMAGE:$WEBSERVER_VERSION
}
### SYSTEM INITIALIZATION ###

## DOCKER NETWORK VARIABLES
## FILESYSTEM VARIABLES
## PORTS VARIABLES
### RESTART SCHEDULER IF NEEDED

VOL=$(check_volumes)
if [ "$VOL" != "1" ]; then
      /usr/bin/docker run -d --rm -v /var/run/docker.sock:/var/run/docker.sock --name $FRAMEWORK_SCHEDULER_NAME $DOCKER_REGISTRY_URL/$FRAMEWORK_SCHEDULER_IMAGE:$FRAMEWORK_SCHEDULER_VERSION
      /usr/bin/docker stop $HOSTNAME;
fi;

exit;

check_framework_scheduler_status $HOSTNAME


# REDIS_SERVER EXISTENCE
## REDIS_PORT EXISTENCE
## VERSION CHECK
start_redis
echo `date`" Redis initialized"
# WEBSERVER EXISTENCE
## WEBSERVER_PORT EXISTENCE
## VERSION CHECK
start_webserver
echo `date`" Webserver initialized"

#### SUMMARY
#########################################
# TESTING
sleep 86400

exit


# poll redis infinitely for scheduler jobs
check_redis_availability $REDIS_SERVER $REDIS_PORT $CURL_RETRIES $CURL_SLEEP_SHORT
echo `date`" Scheduler initialized, starting listening for events"
while true; do

      IDS=""

      # GET DEPLOYMENT IDs FROM generate key
      IDS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS web_in)
      if [[ "$IDS" != "0" && "$IDS" != "" ]]; then

            # PROCESSING IDS
            for I in $(echo $IDS); do

                  ### READ DATA FROM REDIS
                 JSON=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT GET $I | base64 -d)
                  DOMAIN=$(echo "$JSON" | jq -r '.DOMAIN')
                  TYPE=$(echo "$JSON" | jq -r '.TYPE')
                  ACTION=$(echo "$JSON" | jq -r '.ACTION')
                  PAYLOAD=$(echo "$JSON" | jq -r '.PAYLOAD')

                  JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="0"' | base64 -w0);
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $I "$JSON_TARGET";
                  
                  if [ "$TYPE" == "DOMAIN" ]; then
                        /scripts/zone2git.sh "$I" "$DOMAIN" "$ACTION" "$PAYLOAD" "$GIT_URL" "$TOKEN" "$REPO";
                  
                  elif [ "$TYPE" == "VPN" ]; then
                        /scripts/create_vpn.sh "$I" "$DOMAIN" "$ACTION" "$PAYLOAD" "$REDIS_SERVER" "$REDIS_PORT" "$NAMESPACE" "$KUBERNETES" "$KUBERNETES_ENVIRONMENT" "$USER_INIT_PATH" "$VERSIONS_CONFIG_FILE" "$DOCKER_REGISTRY_URL" "$SMARTHOST_PROXY_PATH" "$MAIN_DOMAIN" "$SOURCE" "$PROXY_DELAY";
                  fi
                        
                  if [ "$?" == "0" ]; then
                        JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="1"' | base64 -w0);
                  else
                        JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="2"' | base64 -w0);
                  fi
                        
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $I "$JSON_TARGET";
                  
                  # MOVE ID from generate into generated
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM web_in $I
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD web_out $I

            done
      fi

      sleep 1
done
