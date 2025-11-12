#!/bin/bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Initializing database"

export AUTHENTICATE=0

. ${SCRIPT_DIR}/start_db_with_socket_file.sh

echo "Creating admin user"

mongosh "${URL_ENCODED_SOCKET_FILE}" --eval "db.createUser({ user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles: [{ role: '$ROLE', db: 'admin' }]})"

if [[ $? -ne 0 ]]; then
   echo "Unable to create admin user"
   mongosh "${URL_ENCODED_SOCKET_FILE}" --eval "db.adminCommand({shutdown:1, timeoutSecs: 1})"
   exit 1
fi

echo "Database finished instantiating"

echo "Shutting down database"
# VV: In MongoDB 5.0 timeout secs is 15
# Docs: https://www.mongodb.com/docs/manual/reference/method/db.shutdownServer/
mongosh "${URL_ENCODED_SOCKET_FILE}" --eval "db.adminCommand({shutdown:1, timeoutSecs: 1})"

echo "Database finished initializing"
