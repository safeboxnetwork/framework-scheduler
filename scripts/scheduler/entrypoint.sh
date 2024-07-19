#! /bin/sh

cd /scripts

DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL
USER_INIT_PATH=$USER_INIT_PATH
REDIS_SERVER=$REDIS_SERVER
REDIS_PORT=$REDIS_PORT

SOURCE=$SOURCE
SMARTHOST_PROXY_PATH=$SMARTHOST_PROXY_PATH

GIT_URL=$GIT_URL
TOKEN=$TOKEN
REPO=$REPO

MAIN_DOMAIN=$MAIN_DOMAIN
VERSIONS_CONFIG_FILE=$VERSIONS_CONFIG_FILE
PROXY_DELAY=$PROXY_DELAY


VERSIONS_CONFIG_FILE=$VERSIONS_CONFIG_FILE

if [ -z "$CURL_SLEEP_SHORT" ]; then
      CURL_SLEEP_SHORT=10
fi

if [ -z "$CURL_RETRIES" ]; then
      CURL_RETRIES=360
fi

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
###

# CHECKING SYSTEM ENVIRONMENTS
## DOCKER VARIABLES
## VERSION CHECK
## FILESYSTEM VARIABLES
## PORTS VARIABLES

# REDIS_SERVER EXISTENCE
## REDIS_PORT EXISTENCE
## VERSION CHECK

# WEBSERVER EXISTENCE
## WEBSERVER_PORT EXISTENCE
## VERSION CHECK

# SUMMARY


# poll redis infinitely for scheduler jobs
check_redis_availability $REDIS_SERVER $REDIS_PORT $CURL_RETRIES $CURL_SLEEP_SHORT
echo "Scheduler initialized, starting listening for deploy events"
while true; do

      IDS=""

      # GET DEPLOYMENT IDs FROM generate key
      IDS=$(redis-cli -h $REDIS_SERVER -p $REDIS_PORT SMEMBERS generate)
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
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SREM generate $I
                  redis-cli -h $REDIS_SERVER -p $REDIS_PORT SADD generated $I

            done
      fi

      sleep 1
done