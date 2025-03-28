# Copyright IBM Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Authors
#  Vassilis Vassiliadis

FROM quay.io/mongodb/mongodb-community-server:6.0-ubi9 AS base

USER root
COPY mongod.conf /etc/mongod.conf

USER mongod
# VV: Set this to YES to delete everything under /data/db/* when mongoDb detects that it runs for the first time
ENV MONGODB_DELETE_DATABASE=NO
COPY scripts/* /opt/

USER root
RUN echo 'You can use the distribution mechanisms of RedHat Linux to read \n\
the licenses of GPL packages in this container image.\n\
\n\
If you would like the source to the GPL packages in this image then \n\
send a request to this address, specifying the package you want and \n\
the name and hash of this image: \n\
\n\
IBM Research Ireland,\n\
IBM Technology Campus\n\
Damastown Industrial Park\n\
Mulhuddart Co. Dublin D15 HN66\n\
Ireland\n' >/gpl-licenses

USER mongod
ENTRYPOINT []
CMD "/opt/run.sh"