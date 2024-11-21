#!/bin/sh

# Initial parameters
DATE=$(date +%F-%H-%M-%S)

# Set env variables
DIR=$DIR

# Triggers by certificate or domain config changes

unset IFS

inotifywait --exclude "\.(swp|tmp)" -m -e CREATE,CLOSE_WRITE,DELETE,MOVED_TO -r $DIR |
    while read dir op file; do
        if [ "${op}" == "CLOSE_WRITE,CLOSE" ]; then
            echo "new file created: $file"
        fi
    done
