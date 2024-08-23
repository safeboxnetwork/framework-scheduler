#! /bin/sh

cd /scripts

DOCKER_REGISTRY_URL=${DOCKER_REGISTRY_URL:-registry.format.hu}
USER_INIT_PATH=$USER_INIT_PATH
GLOBAL_VERSION=${GLOBAL_VERSION:-1.0.1}

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

INSTALL_KEY=${INSTALL_KEY:-"LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUJsd0FBQUFkemMyZ3RjbgpOaEFBQUFBd0VBQVFBQUFZRUE5a3NPaTVyaVFvczB3SVU0Y1ZQYmFmYlpuVDE4OE4rWHp4OEEra2h5STBEd3ZvRytMQjFzCitIcm1UZGZ0eWhNM0wzeWlSYms3b0U3c2VrSkhSMEIrV0dsSVNBcjFiZml6NWtWWmdvd2xoUU1KalVuV1B1bWZYZmVneHcKSDlrcFdrWW9UalFiR01INTV6d3M3V2NxREVjRnFTU0pWYytVYVQ3L2cvSGJFYVZNTW9MdDdabnl3UjRJLzhqSW8vM2llcwpGZStyLzRmbDh3cHRBS3gxUzB4SmdpMDlrbWJVMHJuN3Njd0l6N2l0TlVyYVNIc2YxZjJqTFIxdjE4a3lISDBBd1dNRmdWCmxlVG0yWVZwd3pnTkZPOVlHL3RhVXlBZ2FsZlp2Syt3VW9DazNWRkx4Y3JlQkRPei9Ka0pQWHF3bHl5NnF6am9zWVJGaVAKNHI3MlZXbEJJSTdYbXNwV0pLc3JIdXdvNWU5dW9QK2pkelhjd0Q3UFlLNm45Q1VSUS9YNFg1ZmV2ZE9QcDlDdFcwTTc5YQpQaVpPMGZpUHoxQzkyb002ZHBGM1ZpTklicjVENzYreXNQcVZCaU5kYjkrWENQVGhMckVObVlrcStoTkdFVlFRN3ZKUnpmCjhVaGFSYjlsM3BBVjZBcUNYU0Z6bm1GR2ZmalVBb2tFRFI3eEwybW5BQUFGaU5DVlZaalFsVldZQUFBQUIzTnphQzF5YzIKRUFBQUdCQVBaTERvdWE0a0tMTk1DRk9IRlQyMm4yMlowOWZQRGZsODhmQVBwSWNpTkE4TDZCdml3ZGJQaDY1azNYN2NvVApOeTk4b2tXNU82Qk83SHBDUjBkQWZsaHBTRWdLOVczNHMrWkZXWUtNSllVRENZMUoxajdwbjEzM29NY0IvWktWcEdLRTQwCkd4akIrZWM4TE8xbktneEhCYWtraVZYUGxHaysvNFB4MnhHbFRES0M3ZTJaOHNFZUNQL0l5S1A5NG5yQlh2cS8rSDVmTUsKYlFDc2RVdE1TWUl0UFpKbTFOSzUrN0hNQ00rNHJUVksya2g3SDlYOW95MGRiOWZKTWh4OUFNRmpCWUZaWGs1dG1GYWNNNApEUlR2V0J2N1dsTWdJR3BYMmJ5dnNGS0FwTjFSUzhYSzNnUXpzL3laQ1QxNnNKY3N1cXM0NkxHRVJZaitLKzlsVnBRU0NPCjE1cktWaVNyS3g3c0tPWHZicUQvbzNjMTNNQSt6MkN1cC9RbEVVUDErRitYM3IzVGo2ZlFyVnRETy9XajRtVHRINGo4OVEKdmRxRE9uYVJkMVlqU0c2K1ErK3ZzckQ2bFFZalhXL2Zsd2owNFM2eERabUpLdm9UUmhGVUVPN3lVYzMvRklXa1cvWmQ2UQpGZWdLZ2wwaGM1NWhSbjM0MUFLSkJBMGU4UzlwcHdBQUFBTUJBQUVBQUFHQkFMaVY1Zy9SQTdQMW1wS1RCWXRCMnRhZXo5CmRkeHU3TDFIM0JjYjBpWUpCMVVqaWxDajhMeXFpcmkwRmFESGYvVU1QQk4ramplNEdZeFBpWUJjMnIwMFUxbXB1THd3Y3AKZHNLa3hRSG5RUk5nQkYra3IvSTBxMkVFZnJYSGt5Q3lFQ0phRCt3alFhNU0xZHR4b3gwRHlsV2VPN1kwWXhyYnYzSUE3bQpTMVg5T1k4OXUwM3dyQlA2QzZxUDgzZWNob21UdFRoZWVjRlVYQ1VaRklyeHZBei9MRkx6a3k0bHdRVVVlZWNCZ21BNEpHCldEUXNPdDdwR2N0dEhXNXU5cVNOTlhSWFZqT2RMQUsxS1cwU1FJbU9lRm4rQjVmbzdRMlo2OHBGTjAzK1FKMGQ3OS9ka3gKcG1IbFZxandMUXNNNkxlNG43cS9BRmh2SCtCUGtnOGdUcXI4eGlmWVBKdm9sY0xRSmhhdXBmaFlrVlVhK1lIdDR6NHBaUAozOHhTUWZOQmlyb1BnT0tnSEprMk5YUGIvREpPWlp0UmxpRnM1TUU3Z1hzY1ZMYUF0c0pUUUcyVlAyNmlOTHc5aFZFblo1CnlqbEZaUk15M2VjL3hka21UQnprWlZDWjBlc0hUN3hxUTJmanc1ejBNR01wWkpkQnVhdG9xODFvWld6dkk3THBKTFFRQUEKQU1CQi93aThlQ3ZId1g3NDJNYnQrQXN3U3IwZkhBMnQ0ZGNmcG9hSHAyeDRzWTJLVG5QNCsrdzEzNkNIZlYrZEJZM2x3SgpySHdqT1k3UzV3aHBseEdCVEg3dVlvUi85Vnh0TE9hS0NFMCtuZFFpY3ZMK0N0VEo4cFBEWFdWZ0dKcTd3TXhTZGMzWVBQCnRkMk1DOEVaVnN6blZ0a09KdlErU2gwK244YjhoYUxsU21NYzJqUU1MVlVUU3F3R1AwK0NLbG9lTzNTWEpsa1R1Y2pCMC8KbkR3dUZwYkl6U3JrOEJaOVl0UWZHY2xLTmpPRzJCOFdiV2FtRmdWUmhsdGYwV2pYSUFBQURCQVB4MmlYZGo0eVBid3RWSApvUlg4UjRZVlZtVXluWGZKb3YySW9mUFJCNVZPNlJmNTNiMUJaYVFEVCs4ZG1ybHNtSWZjaG5oQVVCdGgrYUQyWDRWVDg1CmIwVDY2UTNSTk05bU16QlROaldvMUhlZnJGQlVLZTZMVldmUDhVOUxoanQ1WVZGNWhTWjdvaGtnNDUxTXRBbXlwYXppZ1MKNWZxVXhDeFFsbjVYd3lrOUd6ZERqVThnOEtNYWJ4WkhhTU9VVHdJN1FXZlV1QWcya1EzUUJNRTZWL2tQOHlKU0V0SHNwOQp1TitiM0JGUlM1U3RIcTVFQnhORTM0Q2IrYmp0S2JZUUFBQU1FQStiNWtQd1ZTamY1bEhkMkpQV29TdWpMZUN5UHJsV2NVClVHWjJIUG9GRGl6SEJrajNmcUhLZXdvbE9ENGZOK0ZHb0VWcTdmbDZ0M3lkWnVOMkxsR0tPejB4dFhoNnlZclVZQlV5d0QKeW9ZMGd4WWY3eUhMYVFhZ1pQNDRqWGhrMzRYTmFwTFRQbGk5R0dCYnZTU0RGQTVIWmRCRnA4cDhLajhDclplKzBRZ3BZMgo3b0o0NzVXVlNkZEZIdkVzcFdoVWg2c3ZqcXM3RHpjdklSdk52M3B4ZWsxenpWY0JsY1RBTW5LeXRKNEg0L0hLc2VYSHIyCnZnOXVTZjFrMTdkMm9IQUFBQURISnZiM1JBYm1WM2VXOXlhd0VDQXdRRkJnPT0KLS0tLS1FTkQgT1BFTlNTSCBQUklWQVRFIEtFWS0tLS0tCg=="}
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

SETUP_VERSION=${SETUP_VERSION:-$GLOBAL_VERSION}

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

VOLUME_MOUNTS="-v SYSTEM_DATA:/etc/system/data -v USER_CONFIG:/etc/user/config:rw -v SYSTEM_CONFIG:/etc/system/config:rw";

service_exec="/usr/bin/docker run --rm \
$DNS \
$CA \
-w /etc/user/config/services/ \
$VOLUME_MOUNTS \
-v /var/run/docker.sock:/var/run/docker.sock \
--env VOLUME_MOUNTS="$(echo $VOLUME_MOUNTS | base64 -w0)" \
--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
--env SETUP_VERSION=$SETUP_VERSION \
--env GLOBAL_VERSION=$GLOBALL_VERSION \
--env HOST_FILE=$HOST_FILE \
$DOCKER_REGISTRY_URL$SETUP:$SETUP_VERSION"

if [ "$SERVICE_DIR" == "" ]; then
	SERVICE_DIR="/etc/user/config/services";
fi;

GIT_REPO=$GIT_REPO
if [ "$GIT_REPO" == "" ]; then
	GIT_REPO=git.format.hu
fi

ORGANIZATION=$ORGANIZATION
if [ "$ORGANIZATION" == "" ]; then
	ORGANIZATION=format
fi

deploy_additionals(){

	local NAME="$1"
	local JSON="$(echo "$2" | base64 -d)"

	# Loop through each key in the JSON and create a variable
	for key in $(echo "$JSON" | jq -r 'keys[]'); do
	  value=$(echo "$JSON" | jq -r --arg k "$key" '.[$k]')
	  eval "$key=$value"
	done

	# env variables are named by "key" from the source template
	# for example NEXTCLOUD_DOMAIN, NEXTCLOUD_USERNAME, NEXTCLOUD_PASSWORD have to be set by according to template

	case "$NAME" in
		"nextcloud")
			deploy_nextcloud
		;;
	esac
}

deploy_nextcloud(){

	DB_MYSQL="$(echo $RANDOM | md5sum | head -c 8)";
        DB_USER="$(echo $RANDOM | md5sum | head -c 8)";
        DB_PASSWORD="$(echo $RANDOM | md5sum | head -c 10)";
        DB_ROOT_PASSWORD="$(echo $RANDOM | md5sum | head -c 10)";

	# TODO repo	
	git clone ssh://$GIT_REPO/$ORGANIZATION/nextcloud.git /tmp/nextcloud;
	sed -i "s/DOMAIN_NAME/$NEXTCLOUD_DOMAIN/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/USERNAME/$NEXTCLOUD_USERNAME/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/USER_PASSWORD/$NEXTCLOUD_PASSWORD/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/DB_MYSQL/$DB_MYSQL/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/DB_USER/$DB_USER/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/DB_PASSWORD/$DB_PASSWORD/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/DB_ROOT_PASSWORD/$DB_ROOT_PASSWORD/g" /tmp/nextcloud/nextcloud-secret.json;
	sed -i "s/DOMAIN_NAME/$NEXTCLOUD_DOMAIN/g" /tmp/nextcloud/domain-nextcloud.json

	cp -rv /tmp/nextcloud/nextcloud-secret.json /etc/user/secret/nextcloud.json;
	
	cp -rv /tmp/nextcloud/nextcloud.json $SERVICE_DIR/nextcloud.json;
	cp -rv /tmp/nextcloud/domain-nextcloud.json $SERVICE_DIR/domain-nextcloud.json;
	cp -rv /tmp/nextcloud/firewall-nextcloud.json $SERVICE_DIR/firewall-nextcloud.json;
	cp -rv /tmp/nextcloud/firewall-nextcloud-server-dns.json $SERVICE_DIR/firewall-nextcloud-server-dns.json;
	cp -rv /tmp/nextcloud/firewall-nextcloud-server-smtp.json $SERVICE_DIR/firewall-nextcloud-server-smtp.json;
}

get_repositories(){

	local REPOS;
	local BASE;
	local TREES="";

	REPOS=$(jq -r .repositories[] /etc/user/config/repositories.json); # list of repos, delimiter by space
	for REPO in $REPOS; do
		BASE=$(basename $REPO | cut -d '.' -f1)
		if [ ! -f "/tmp/$BASE" ]; then
			git clone $REPO /tmp/$BASE;
		else
			git pull $REPO /tmp/$BASE;
		fi;
		if [ -f "/tmp/$BASE/applications-tree.json" ]; then
			TREES=$TREES" /tmp/$BASE/applications-tree.json"
		fi;
	done;

	echo $TREES;
}

check_volumes(){

	RET=1;
	if [ ! -d "/etc/system/data/" ]; then
		/usr/bin/docker volume create SYSTEM_DATA;
		RET=0;
	fi
	if [ ! -d "/etc/system/config/" ]; then
		/usr/bin/docker volume create SYSTEM_CONFIG;
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

	if [ ! -d "/etc/system" ]; then
		mkdir "/etc/system"
	fi;

	if [ ! -d "/etc/user/secret" ]; then
		mkdir -p "/etc/user/secret"
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
	if [ "$ACTUAL_FRAMEWORK_SCHEDULER_NAME" != "$FRAMEWORK_SCHEDULER_NAME" ]; then
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

add_repository() {
	NEW_REPO="$1";

	if [ ! -f "/etc/user/config/repositories.json" ]; then
		create_repositories_json;
	fi
	UPDATED_REPOS=$(cat /etc/user/config/repositories.json | jq '.repositories += ["'$NEW_REPO'"]')
	echo "$UPDATED_REPOS" | jq -r . > /etc/user/config/repositories.json
}

create_repositories_json() {
		{
			echo '
{
	"repositories": [ "git@git.format.hu:format/default-applications-tree.git" ]
}
';
		} | jq -r . > /etc/user/config/repositories.json
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
      B64_JSON="$2"
      DATE=$( date +"%Y%m%d%H%M")

      # Executing task
      echo "TASK: $(echo $TASK | cut -d ':' -f1)"
      TASK_NAME=$(echo $TASK | cut -d ':' -f1);

    # checking sytem status
    SYSTEM_STATUS=$(ls /etc/user/config/services/*.json |grep -v service-framework.json)
    if [ "$SYSTEM_STATUS" != "" ]; then
	    INSTALL_STATUS="1"; # has previous install
    else
	    INSTALL_STATUS="2"; # new install
    fi

      if [ "$TASK_NAME" == "install" ]; then
            JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "0" }' | jq -r . | base64 -w0); # install has started
      	    redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET"; # web_in

    	    #if [ "$INSTALL_STATUS" == "2" ]; then 
	    # force install?
	    	# TODO - start install.sh
            	sh /scripts/install.sh "$B64_JSON" "$service_exec" "true" "$INSTALL_KEY" "$GLOBAL_VERSION"
	    #fi;
            JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'" }' | jq -r . | base64 -w0);

      elif [ "$TASK_NAME" == "system" ]; then
	#SYSTEM_LIST="core-dns.json cron.json domain-local-backend.json firewall-letsencrypt.json firewall-local-backend.json firewall-localloadbalancer-dns.json firewall-localloadbalancer-to-smarthostbackend.json firewall-smarthost-backend-dns.json firewall-smarthost-loadbalancer-dns.json firewall-smarthost-to-backend.json firewall-smarthostloadbalancer-from-publicbackend.json letsencrypt.json local-backend.json local-proxy.json service-framework.json smarthost-proxy-scheduler.json smarthost-proxy.json"
	SYSTEM_LIST="core-dns.json cron.json letsencrypt.json local-proxy.json service-framework.json smarthost-proxy-scheduler.json smarthost-proxy.json";
	INSTALLED_SERVICES=$(ls /etc/user/config/services/*.json );
	SERVICES="";
	for SERVICE in $(echo $INSTALLED_SERVICES); do
		for ITEM in $SYSTEM_LIST; do
			if [ "$(basename $SERVICE)" == "$ITEM" ]; then # system file
				CONTENT=$(cat $SERVICE | base64 -w0);
				if [ "$SERVICES" != "" ]; then
					SEP=",";
				else
					SEP="";
				fi;
				SERVICES=$SERVICES$SEP'"'$(cat $SERVICE | jq -r .main.SERVICE_NAME)'": "'$CONTENT'"';
				break;
			fi;
		done;
	done

	JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0);

      elif [ "$TASK_NAME" == "deployments" ]; then
	        DEPLOYMENTS=""
		TREES=$(get_repositories);
		for TREE in $TREES do;
			APPS=$(jq -rc '.apps[]' $TREE);
			for APP in $APPS ; do
				APP_NAME=$(echo "$APP" | jq -r '.name')
				APP_VERSION=$(echo "$APP" | jq -r '.version')
				  if [ "$DEPLOYMENTS" != "" ]; then
					  SEP=",";
				  else
					  SEP="";
				  fi;
				  DEPLOYMENTS=$DEPLOYMENTS$SEP'"'$APP_NAME'": "'$APP_VERSION'"';
			done;
		done;
		  if [ "$DEPLOYMENTS" == "" ]; then
			  DEPLOYMENTS='"deployments": "NONE"';
	          fi;

                  INSTALLED_SERVICES=$(ls /etc/user/config/services/service-*.json );
		  SERVICES="";
                  for SERVICE in $(echo $INSTALLED_SERVICES); do
			  if [ "$(basename $SERVICE)" != "service-framework.json" ]; then # NOT system file
				  CONTENT=$(cat $SERVICE | base64 -w0);
				  if [ "$SERVICES" != "" ]; then
					  SEP=",";
				  else
					  SEP="";
				  fi;
				  SERVICES=$SERVICES$SEP'"'$(cat $SERVICE | jq -r .main.SERVICE_NAME)'": "'$CONTENT'"';
			  fi;
                  done
		  if [ "$SERVICES" == "" ]; then
			  SERVICES='"services": "NONE"';
	          fi;

            JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "INSTALL_STATUS": "'$INSTALL_STATUS'", "DEPLOYMENTS": {'$DEPLOYMENTS'}, "INSTALLED_SERVICES": {'$SERVICES'} }' | jq -r . | base64 -w0);

      elif [ "$TASK_NAME" == "deployment" ]; then
		JSON="$(echo $B64_JSON | base64 -d)"
		DEPLOY_NAME=$(echo "$JSON" | jq -r .NAME)
		DEPLOY_ACTION=$(echo "$JSON" | jq -r .ACTION)
	        TREES=$(get_repositories);

		for TREE in $TREES do;
			APPS=$(jq -rc '.apps[]' $TREE);
			for APP in $APPS ; do
				APP_NAME=$(echo "$APP" | jq -r '.name')
				APP_VERSION=$(echo "$APP" | jq -r '.version')
				APP_DIR=$(dirname $TREE)"/"$APP_NAME
				APP_TEMPLATE=$(dirname $TREE)"/"$APP_NAME"/template.json"
				echo $APP_TEMPLATE
				if [ "$APP_NAME" == "$DEPLOY_NAME" ]; then
					if [ "$DEPLOY_ACTION" == "ask" ]; then
						PAYLOAD=$(cat $APP_TEMPLATE | base64 -d)
						JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "PAYLOAD": "'$PAYLOAD'" }' | jq -r . | base64 -w0);
					elif [ "$DEPLOY_ACTION" == "deploy" ]; then
						DEPLOY_PAYLOAD=$(echo "$JSON" | jq -r .PAYLOAD)
						deploy_additionals "$DEPLOY_NAME" "$DEPLOY_PAYLOAD"
						JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "'$STATUS'" }' | jq -r . | base64 -w0);
					fi;
				fi;
			done;
		done;

      elif [ "$TASK_NAME" == "repositories" ]; then
		if [ ! -f "/etc/user/config/repositories.json" ]; then
			create_repositories_json;
		fi
            REPOS=$(cat /etc/user/config/repositories.json);
	    if [ "$REPOS" != "" ]; then
		    EXISTS="1";
	    	    REPOS=$(echo "$REPOS" | base64 -w0);
            else
		    EXISTS="0";
		    REPOS="";
	    fi;
            JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "EXISTS": "'$EXISTS'", "REPOSITORIES": "'$REPOS'" }' | jq -r . | base64 -w0);

      elif [ "$TASK_NAME" == "add_repository" ]; then
		JSON="$(echo $B64_JSON | base64 -d)"
		NEW_REPO=$(echo "$JSON" | jq -r .NEW_REPO)
		add_repository "$NEW_REPO"
            	JSON_TARGET=""

      elif [ "$TASK_NAME" == "containers" ]; then # TODO
	    CONTAINERS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep -v framework-scheduler);
	    RESULT=$(echo "$CONTAINERS" | base64 -w0);
            JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "RESULT": "'$RESULT'" }' | jq -r . | base64 -w0);

      fi 

      if [ "$JSON_TARGET" != "" ]; then
		redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";
      fi 

}

check_running() {

	DOCKERD_STATUS="0";

	### From Redis
	# bridge check
	BRIDGE_NUM=$($SUDO_CMD docker network ls | grep bridge | awk '{print $2":"$3}' | sort | uniq | wc -l);

	CONTAINER_NUM=$($SUDO_CMD docker ps -a | wc -l);

	if [ "$BRIDGE_NUM" != "1" ] && [ "$CONTAINER_NUM" != "1" ]; then

		echo "There are existing containers and/or networks.";
		echo "Please select from the following options (1/2/3):";

		echo "1 - Delete all existing containers and networks before installation";
		echo "2 - Stop the installation process";
		echo "3 - Just continue on my own risk";
		
		read -r ANSWER;

		if [ "$ANSWER" == "1" ]; then
			echo "1 - Removing exising containers and networks";
			# delete and continue
			$SUDO_CMD docker stop $($SUDO_CMD docker ps |grep Up | awk '{print $1}')
			$SUDO_CMD docker system prune -a

		elif [ "$ANSWER" == "3" ]; then
			echo "3 - You have chosen to continue installation process."

		else # default: 2 - stop installastion
			echo "2 - Installation process was stopped";
			exit;
		fi;

	fi;
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

## DOCKER NETWORK VARIABLES
## FILESYSTEM VARIABLES
## PORTS VARIABLES
### RESTART SCHEDULER IF NEEDED

SN=$(check_subnets)
if [ "$SN" != "1" ]; then
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
		-v SYSTEM_CONFIG:/etc/system/config \
		-v SYSTEM_LOG:/etc/system/log \
		-v USER_DATA:/etc/user/data \
		-v USER_CONFIG:/etc/user/config \
	  	--env WEBSERVER_PORT=$WEBSERVER_PORT \
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

# STARTING SCHEDULER PROCESSES
#/scripts/scheduler.sh &

while true; do

      TASKS=""

      # GET DEPLOYMENT IDs FROM generate key
      TASKS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS web_in)
      if [[ "$TASKS" != "0" && "$TASKS" != "" ]]; then

            # PROCESSING TASK
            for TASK in $(echo $TASKS); do

                  ### READ TASKS FROM REDIS
                  B64_JSON=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT GET $TASK)

                  JSON_TARGET=$(echo $B64_JSON | base64 -d | jq -rc .'STATUS="0"' | base64 -w0);
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET";

                  execute_task "$TASK" "$B64_JSON"
                  
                  # MOVE TASK from web_in into web_out
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM web_in $TASK
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD web_out $TASK

            done
      fi

      sleep 1
done
