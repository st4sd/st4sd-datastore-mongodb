#!/usr/bin/env bash
#
# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set +x

export HERMES_OC_PROJECT=${HERMES_OC_PROJECT:-foc-materials-mvp2-dev}

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xvf openshift-client-linux.tar.gz
rm openshift-client-linux.tar.gz

chmod +x oc kubectl
export PATH=$PATH:${PWD}
oc login "${HERMES_OC_LOGIN_URL}" -u "${HERMES_OC_USERNAME}" -p "${HERMES_OC_AUTH}" --insecure-skip-tls-verify=true

# VV: Trigger image-stream `st4sd-datastore-mongodb`
oc project ${HERMES_OC_PROJECT}
oc import-image st4sd-datastore-mongodb --from=${DOCKER_REGISTRY}/st4sd-datastore-mongodb:latest
