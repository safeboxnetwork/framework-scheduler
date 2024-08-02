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


check_volumes(){

	RET=1;
	if [ ! -d "/etc/system/data/" ]; then
		/usr/bin/docker volume create SYSTEM_DATA;
		RET=0;
	fi
      	if [ ! -d "/etc/system/log/" ]; then
		/usr/bin/docker volume create SYSTEM_LOG;
		RET=0;
	fi
	if [ ! -d "/etc/user/data/" ]; then
		/usr/bin/docker volume create USER_DATA;
		RET=0;
	fi;
	if [ ! -d "/etc/user/config/" ]; then
		/usr/bin/docker volume create USER_CONFIG;
		RET=0;
	fi;

	echo $RET;
}

check_dirs_and_files(){

	RET=0;
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

	RET=1;
	SUBNETS=$(for ALL in $(/usr/bin/docker network ls | grep bridge | awk '{print $1}') ; do /usr/bin/docker network inspect $ALL --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' ; done)

	RES=$(echo "$SUBNETS" | grep "172.19.");
	if [ "$RES" != "" ]; then
		for R in $RES ; do
			NUMBER=$(echo $R | cut -d '.' -f3);
			if [[ $NUMBER -ge 0 && $NUMBER -le 254 ]]; then
				RET=0
			fi;
		done;
	fi;
	echo $RET;
}

check_framework_scheduler_status(){

	ACTUAL_FRAMEWORK_SCHEDULER_NAME=$1;

	RET=1;
	if "$ACTUAL_FRAMEWORK_SCHEDULER_NAME" != "$FRAMEWORK_SCHEDULER_NAME"; then
		RET=0;
	else
		desired_subnet=$FRAMEWORK_SCHEDULER_NETWORK_SUBNET
		existing_subnets=$(/usr/bin/docker network inspect $(/usr/bin/docker network ls -q) --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')

		# Check if the desired subnet is in the list of existing subnets
		if echo "$existing_subnets" | grep -q "$desired_subnet"; then
			if [ "$(/usr/bin/docker network inspect $FRAMEWORK_SCHEDULER_NETWORK --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')" != "$FRAMEWORK_NETWORK_SUBNET" ]; then
				RET=0;
			fi
		else
			RET=0;
		fi
	fi

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
';
		} > /etc/user/config/system.json
}

create_user_json() {
	touch /etc/user/config/user.json
}

create_framework_json() {

    ADDITIONAL=""
    ADDITIONAL='"EXTRA": "--label logging=promtail_user --label logging_jobname=containers --restart unless-stopped", "PRE_START": [], "DEPEND": [], "CMD": ""'

    echo '{
  "main": {
    "SERVICE_NAME": "framework"
  },
  "containers": [
    {
      "IMAGE": "redis:'$REDIS_VERSION'",
      "NAME": "'$REDIS_SERVER'",
      "UPDATE": "true",
      "MEMORY": "64M",
      "NETWORK": "'$FRAMEWORK_SCHEDULER_NETWORK'",
      '$ADDITIONAL',
      "PORTS":[
        { "SOURCE": "null",
          "DEST": "6379",
          "TYPE": "tcp"
        }
            ],
      "POST_START": []
    },
    {
      "IMAGE": "'$DOCKER_REGISTRY_URL'/'$FRAMEWORK_SCHEDULER_IMAGE':'$FRAMEWORK_SCHEDULER_VERSION'",
      "NAME": "'$FRAMEWORK_SCHEDULER_NAME'",
      "UPDATE": "true",
      "MEMORY": "256M",
      "NETWORK": "'$FRAMEWORK_SCHEDULER_NETWORK'",
      '$ADDITIONAL',
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
      "POST_START": []
    }
  ]
}
  ' | jq -r . >/etc/user/config/services/service-framework.json
}

execute_task() {
      TASK="$1"
      JSON="$2 | base64 -d"

      # Executing task
      echo "TASK: $(echo $TASK | cut -d ':' -f1)"
      TASK_NAME=$(echo $TASK | cut -d ':' -f1);

      if [ "$TASK_NAME" == "init" ]; then
            # checking sytem status
            SYSTEM_STATUS=$(ls /etc/user/config/services/*.json |grep -v service-framework.json)
                  INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json | | cut -d '.' -f1);
		  SERVICES="";
                  for SERVICE in $(echo $INSTALLED_SERVICES); do
			  CONTENT=$(cat "/etc/user/config/services/"$SERVICE);
			  if [ "$SERVICES" != "" ]; then
				  SERVICES=",";
		  	  fi;
			  SERVICES=$SERVICES'"'$SERVICE'": { "'$CONTENT'"}';
                  done
                  PAYLOAD=$(echo '{ "INSTALLED_SERVICES": { '$SERVICES' } }' | jq -r . | base64 -w0);
           
	    if [ "$SYSTEM_STATUS" != "" ]; then
                  JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="1"' | jq -rc .'PAYLOAD="'$PAYLOAD'"' | base64 -w0);
            else
                  JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="2"' | jq -rc .'PAYLOAD="'$PAYLOAD'"' | base64 -w0);      
            fi

      fi 

      redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";
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

## DOCKER NETWORK VARIABLES
## FILESYSTEM VARIABLES
## PORTS VARIABLES
### RESTART SCHEDULER IF NEEDED

SN=$(check_subnets)
if [ "$SN" != "1"]; then
	echo "Desired network subnet not available";
	exit;
fi;
STATUS=$(check_framework_scheduler_status $HOSTNAME)
if [ "$STATUS" != "1" ]; then
	/usr/bin/docker network create $FRAMEWORK_SCHEDULER_NETWORK --subnet $FRAMEWORK_SCHEDULER_NETWORK_SUBNET;
fi;

VOL=$(check_volumes)
if [ "$VOL" != "1" ]; then
      /usr/bin/docker run -d \
	  	-v /var/run/docker.sock:/var/run/docker.sock \
		-v SYSTEM_DATA:/etc/system/data \
		-v SYSTEM_LOG:/etc/system/log \
		-v USER_DATA:/etc/user/data \
		-v USER_CONFIG:/etc/user/config \
	  	--name $FRAMEWORK_SCHEDULER_NAME \
	  	--network $FRAMEWORK_SCHEDULER_NETWORK \
	  $DOCKER_REGISTRY_URL/$FRAMEWORK_SCHEDULER_IMAGE:$FRAMEWORK_SCHEDULER_VERSION;
      /usr/bin/docker stop $HOSTNAME;
fi;

DF=$(check_dirs_and_files);
if [ "$DF" != "1" ]; then
	create_system_json;
	create_user_json;
	create_framework_json;
fi;


# START SERVICES
$service_exec service-framework.containers.redis-server start &
$service_exec service-framework.containers.webserver start &
sleep 5;


# poll redis infinitely for scheduler jobs
check_redis_availability $REDIS_SERVER $REDIS_PORT $CURL_RETRIES $CURL_SLEEP_SHORT
echo `date`" Scheduler initialized, starting listening for events"
while true; do

      TASKS=""

      # GET DEPLOYMENT IDs FROM generate key
      TASKS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS web_in)
      if [[ "$TASKS" != "0" && "$TASKS" != "" ]]; then

            # PROCESSING TASK
            for TASK in $(echo $TASKS); do

                  ### READ TASKS FROM REDIS
                  JSON=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT GET $TASK | base64 -d)

                  JSON_TARGET=$(echo $JSON | jq -rc .'STATUS="0"' | base64 -w0);
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";

                  execute_task $TASK $JSON &
                  
                  # MOVE TASK from generate into generated
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM web_in $TASK
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD web_out $TASK

            done
      fi

      sleep 1
done
