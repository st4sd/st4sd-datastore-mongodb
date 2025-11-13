#!/bin/bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export MONGO_BIND_IP=${MONGO_BIND_IP:-127.0.0.1}

. ${SCRIPT_DIR}/start_db_with_socket_file.sh

if [[ $? -ne 0 ]]; then
   echo "Failed to start db"
   exit 1
fi

mongosh "${URL_ENCODED_SOCKET_FILE}" -u "${MONGODB_USERNAME}" -p "${MONGODB_PASSWORD}" --authenticationDatabase admin --eval '
  function ensureOk(desc, cmd) {
    const res = db.adminCommand(cmd);

    if (!res || res.ok !== 1) {
      print("ERROR:", desc, "failed");
      if (res) printjson(res);
      quit(1);
    }

    return res;
  }

  print("Running upgrade logic");

  const res = ensureOk("get featureCompatibilityVersion", { getParameter: 1, featureCompatibilityVersion: 1 });
  let v = res.featureCompatibilityVersion;

  if (v && typeof v === "object" && v.version) {
    v = v.version;
  }

  if (v && typeof v === "string") {
    print("Version", v);
    if (v == "5.0") {
      print("Upgrading to 6.0");
      ensureOk("setFeatureCompatibilityVersion to 6.0", { setFeatureCompatibilityVersion: "6.0" });
    } else {
      print("No upgrade action necessary");
    }
  } else {
    print("Cannot determine current version");
    print(v);
    quit(2);
  }
'

exit_code=$?

echo "Shutting down database"
mongosh "${URL_ENCODED_SOCKET_FILE}" -u "${MONGODB_USERNAME}" -p "${MONGODB_PASSWORD}" --authenticationDatabase admin --eval 'db.adminCommand({shutdown:1, timeoutSecs: 1});'

exit $exit_code