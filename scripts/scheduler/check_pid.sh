#!/bin/sh

PID="$1"
TASK="$2"
DATE="$3";
REDIS_SERVER="$4"
REDIS_PORT="$5"

if [ "$PID" != "" ]; then

	debug "JSON_TARGET: $JSON_TARGET"

	wait $PID

	JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "2" }' | jq -r . | base64 -w0)
	debug "JSON_TARGET: $JSON_TARGET"

	redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET"

fi;

