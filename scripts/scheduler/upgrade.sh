#!/bin/sh

B64_JSON=$1
SERVICE_EXEC=$2
GLOBAL_VERSION=$4

for SERVICE in $(echo $B64_JSON | base64 -d | jq -r 'keys[]'); do

done
