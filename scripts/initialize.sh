#!/bin/bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis


MONGODB_USERNAME=${MONGODB_USERNAME:-admin}
export INIT_PORT=${MONGODB_INIT_PORT:-64942}
export LOCATION_DATABASE=${LOCATION_DATABASE:-/data/db/mongodb}

ROLE='root'

socket_file="/tmp/mongodb-${INIT_PORT}.sock"

echo "Starting mongod with no auth to setup admin account"
/usr/bin/mongod --bind_ip "${socket_file}" --port "${INIT_PORT}" --dbpath="${LOCATION_DATABASE}" --nojournal &

# Here, we just spam the creation of the admin user and immediately shutoff the server
# We don't want to wait for mongod to become available before attempting to initialize
# the user. This is to reduce the chances of some random process running on the
# same cluster and figuring out where we're about to create the unix socket
# connecting to it before us.

# VV TODO: Identify a way to perform this step as part of `/usr/bin/mongod`.
# VV FIXME: Create a second user who's not an admin but has R/W access
# VV FIXME: Use a different database ... admin is not meant to hold data

# VV: Looks weird because we have to url-encode path to unix-socket
# Docs: https://www.mongodb.com/docs/manual/reference/connection-string/#unix-domain-socket
url_encoded_socket_file="mongodb://%2Ftmp%2Fmongodb-${INIT_PORT}.sock/admin"
while true
do
  /usr/bin/mongosh "${url_encoded_socket_file}" --eval "db.createUser({ user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles: [{ role: '$ROLE', db: 'admin' }]})"
  if [[ $? -eq 0 ]]; then
    break
  fi
done

echo "Shutting down database"
# VV: In MongoDB 5.0 timeout secs is 15
# Docs: https://www.mongodb.com/docs/manual/reference/method/db.shutdownServer/
/usr/bin/mongosh "${url_encoded_socket_file}" --eval "db.adminCommand({shutdown:1, timeoutSecs: 15})"

echo "Database finished initializing - starting it again in 20 seconds"

sleep 20
