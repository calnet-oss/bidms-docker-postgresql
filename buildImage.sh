#!/bin/bash

#
# Copyright (c) 2017, Regents of the University of California and
# contributors.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

function check_exit {
  error_code=$?
  if [ $error_code != 0 ]; then
    echo "ERROR: last command exited with an error code of $error_code"
    exit $error_code
  fi
}

if [ -f config.env ]; then
  . ./config.env || check_exit
else
  cat << EOF
Warning: There is no config.env file.  It is recommended you copy
config.env.template to config.env and edit it before running this, otherwise
the argument defaults in the Dockerfile will be used.
EOF
fi

if [ -z "$BUILDTIME_CMD" ]; then
  # Can be overriden in config.env to be buildah instead.
  BUILDTIME_CMD=docker
fi
if [ -z "$RUNTIME_CMD" ]; then
  # Can be overriden in config.env to be podman instead.
  RUNTIME_CMD=docker
fi

if [ ! -z "$NETWORK" ]; then
  echo "NETWORK=$NETWORK"
  ARGS+="--network $NETWORK "
fi

if [ ! -z "$POSTGRESQL_VERSION" ]; then
  echo "POSTGRESQL_VERSION=$POSTGRESQL_VERSION"
  ARGS+="--build-arg POSTGRESQL_VERSION=$POSTGRESQL_VERSION "
else
  echo "ERROR: Required POSTGRESQL_VERSION value missing from $CONFIG_FILE"
  exit 1
fi

if [ ! -z "$APT_PROXY_URL" ]; then
  ARGS+="--build-arg APT_PROXY_URL=$APT_PROXY_URL "
elif [ -e $HOME/.aptproxy ]; then
  apt_proxy_url=$(cat $HOME/.aptproxy)
  ARGS+="--build-arg APT_PROXY_URL=$apt_proxy_url "
fi

if [ ! -z "$(echo \"$BUILDTIME_CMD\" | grep buildah)" ]; then
  build_cmd="$BUILDTIME_CMD build-using-dockerfile"
else
  build_cmd="$BUILDTIME_CMD build"
fi

echo "Using ARGS: $ARGS"
($build_cmd $ARGS -f imageFiles/Dockerfile.base -t bidms/postgresql-base:${POSTGRESQL_VERSION} imageFiles && \
$build_cmd $ARGS -f imageFiles/Dockerfile -t bidms/postgresql:${POSTGRESQL_VERSION} imageFiles) || check_exit

#
# We want to temporarily start up the image so we can copy the contents of
# /var/lib/postgresql to the host.  On subsequent container runs, we will
# mount this host directory into the container.  i.e., we want to persist
# PostgreSQL database data across container runs.
#
if [ ! -z "$HOST_POSTGRESQL_DIRECTORY" ]; then
  if [ -e $HOST_POSTGRESQL_DIRECTORY ]; then
    echo "$HOST_POSTGRESQL_DIRECTORY on the host already exists.  Not copying anything."
    echo "If you want a clean install, delete $HOST_POSTGRESQL_DIRECTORY and re-run this script."
    exit
  fi
  echo "Temporarily starting the container to copy /var/lib/postgresql to host"
  NO_INTERACTIVE="true" NO_HOST_POSTGRESQL_DIRECTORY="true" ./runContainer.sh || check_exit
  TMP_POSTGRESQL_HOST_DIR=$(./getPostgresqlHostDir.sh)
  if [[ $? != 0 || -z "$TMP_POSTGRESQL_HOST_DIR" ]]; then
    echo "./getPostgresqlHostDir.sh failed"
    echo "Stopping the container."
    $RUNTIME_CMD stop bidms-postgresql
    exit 1
  fi

  echo "Temporary host PostgreSQL directory: $TMP_POSTGRESQL_HOST_DIR"
  echo "$HOST_POSTGRESQL_DIRECTORY does not yet exist.  Copying from temporary location."
  echo "You must have sudo access for this to work and you may be prompted for a sudo password."
  echo "Waiting 10 seconds for PostgreSQL to start."
  sleep 10
  sudo cp -pr $TMP_POSTGRESQL_HOST_DIR $HOST_POSTGRESQL_DIRECTORY
  if [ $? != 0 ]; then
    echo "copy from $TMP_POSTGRESQL_HOST_DIR to $HOST_POSTGRESQL_DIRECTORY failed"
    echo "Stopping the container."
    $RUNTIME_CMD stop bidms-postgresql
    exit 1
  fi
  echo "Successfully copied to $HOST_POSTGRESQL_DIRECTORY"

  echo "Stopping the container."
  $RUNTIME_CMD stop bidms-postgresql || check_exit
fi
