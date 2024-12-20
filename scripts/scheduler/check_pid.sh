#!/bin/sh

PID="$1"
SHARED="$2"
TASK="$3"
DATE="$4";
DEBUG="$5";

# writes debug message if DEBUG variable is set
debug() {
    if [ $DEBUG -eq 1 ]; then
        echo "DEBUG: "$1 $2 $3
    fi
}

if [ "$PID" != "" ]; then

	debug "BACKGROUND PID: $PID"

	#wait $PID
	while pwdx $PID > /dev/null; do
		debug "RUNNING PROCESS: $TASK - PID: $PID"
		sleep 2
	done

	JSON_TARGET=$(echo '{ "DATE": "'$DATE'", "STATUS": "2" }' | jq -r . | base64 -w0)
	debug "JSON_TARGET: $JSON_TARGET"

        echo $JSON_TARGET | base64 -d >$SHARED/output/$TASK.json
	#redis-cli -h $REDIS_SERVER -p $REDIS_PORT SET $TASK "$JSON_TARGET"

fi;

