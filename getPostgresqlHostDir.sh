#!/bin/bash

. ./config.env

if [ -z "$RUNTIME_CMD" ]; then
  RUNTIME_CMD=docker
fi

CONTAINER_DIR="/var/lib/postgresql"
INSPECT=$($RUNTIME_CMD inspect bidms-postgresql | sed -e '/Source/,/Destination/!d')

while read -ra arr; do
  if [ "${arr[0]}" == '"Source":' ]; then
    src=${arr[1]}
  elif [[ "${arr[0]}" == '"Destination":' && "${arr[1]}" == "\"$CONTAINER_DIR\"," ]]; then
    postgresql_src=$src
  fi
done  <<< "$INSPECT"
postgresql_src=$(echo $postgresql_src|cut -d'"' -f2)

echo $postgresql_src
