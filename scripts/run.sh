#!/bin/bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis

export LOCATION_DATABASE=${LOCATION_DATABASE:-/data/db/mongodb}

if [[ ${MONGODB_DELETE_DATABASE} == "YES" ]];then
  echo "Clearing data under ${LOCATION_DATABASE}"
  rm -rf ${LOCATION_DATABASE}
fi

echo "Database location ${LOCATION_DATABASE}"
mkdir -p ${LOCATION_DATABASE}

if [[ -f ${LOCATION_DATABASE}/mongod.lock ]]; then
  echo "Unclean shutdown of mongod - deleting (${LOCATION_DATABASE}/mongod.lock)."
  rm -f ${LOCATION_DATABASE}/mongod.lock
else
  echo "Mongod was shutdown cleanly"
fi

# Initialize first run
if [[ ! -f ${LOCATION_DATABASE}/.firstrun ]]; then
   echo "Database has not been initialized yet - Initializing it now"
   /opt/initialize.sh
   if [[ $? -ne 0 ]]; then
     echo "Failed to initialize"
     exit 1
   fi
   touch ${LOCATION_DATABASE}/.firstrun
else
   echo "Database has already been initialized - Skipping initialization script and trying to upgrade it"
   /opt/upgrade.sh
   if [[ $? -ne 0 ]]; then
     echo "Failed to upgrade"
     exit 1
   fi
   echo "Waiting for 5 seconds"
   sleep 5
fi

echo "Starting mongod at ${LOCATION_DATABASE}"
mongod --dbpath="${LOCATION_DATABASE}" --bind_ip_all --auth $@
