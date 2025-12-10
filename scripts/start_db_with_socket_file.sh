#!/bin/bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis

MONGODB_USERNAME=${MONGODB_USERNAME:-admin}
export INIT_PORT=${MONGODB_INIT_PORT:-64942}
export LOCATION_DATABASE=${LOCATION_DATABASE:-/data/db/mongodb}

AUTHENTICATE=${AUTHENTICATE:-1}

ROLE='root'

socket_file="/tmp/mongodb-${INIT_PORT}.sock"

# VV: Looks weird because we have to url-encode path to unix-socket
# Docs: https://www.mongodb.com/docs/manual/reference/connection-string/#unix-domain-socket
export URL_ENCODED_SOCKET_FILE="mongodb://%2Ftmp%2Fmongodb-${INIT_PORT}.sock/admin"

echo "Starting mongod with a socket file"

AUTH_ARGS=""
if [ "${AUTHENTICATE}" -eq "1" ]; then
  AUTH_ARGS="-u ${MONGODB_USERNAME} -p ${MONGODB_PASSWORD} --authenticationDatabase admin"
fi

mongod --bind_ip "${socket_file}" --port "${INIT_PORT}" --dbpath="${LOCATION_DATABASE}" &

# VV FIXME: Create a second user who's not an admin but has R/W access
# VV FIXME: Use a different database ... admin is not meant to hold data

echo "Waiting for DB to start"

timeout_seconds=${MONGO_INIT_SECONDS_TIMEOUT:-120}
start=$(date +%s)

echo "Waiting for the mongodb server to accept connections."
echo "Will wait for up to ${timeout_seconds} before exiting with an error."

until mongosh "${URL_ENCODED_SOCKET_FILE}" ${AUTH_ARGS} --eval "db.adminCommand('ping')"; do
  sleep 1

  now=$(date +%s)
  waiting_for=$(( now - start ))

  if (( waiting_for > timeout_seconds )); then
        echo "Unable to connect to the database after ${timeout_seconds} seconds. This can be a symptom of a misconfigured database please read the logs and address any issues."
        exit 1
  fi
done

echo "mongod running with socket file ${URL_ENCODED_SOCKET_FILE}"