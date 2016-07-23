#!/bin/bash
if [ -z ${MODULE+x} ]; then echo "Error: The module name must be specified in the MODULE enviroment variable"; exit 1; fi
if [ -z ${LICENCE+x} ]; then echo "Error: A licence for AMP from cubecoders.com is required and must be specified in the environment variables"; exit 1; fi

HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-"8080"}
USERNAME=${USERNAME:-"admin"}
PASSWORD=${PASSWORD:-"password"}
INSTANCE_NAME=${INSTANCE_NAME:-"instance"}
EXTRAS=${EXTRAS:-""}


if [ ! -d ~/.ampdata/instances/instance/ ]; then
    echo "Creating $MODULE instance."
    ./ampinstmgr CreateInstance $MODULE $INSTANCE_NAME $HOST $PORT $LICENCE $PASSWORD +Core.Login.Username $USERNAME $EXTRAS
    (cd /ampdata/instances/$INSTANCE_NAME && exec ./AMP_Linux_x86_64)
else
    (cd /ampdata/instances/$INSTANCE_NAME && ./AMP_Linux_x86_64 +Core.AMP.LicenceKey $LICENCE && exec ./AMP_Linux_x86_64)
fi
