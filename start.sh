#!/bin/sh
set -e

if [ -z ${MODULE} ]; then echo "Error: The module name must be specified in the MODULE enviroment variable"; exit 1; fi
if [ -z ${LICENCE} ]; then echo "Error: A licence for AMP from cubecoders.com is required and must be specified in the environment variables"; exit 1; fi

HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-"8080"}
USERNAME=${USERNAME:-"admin"}
PASSWORD=${PASSWORD:-"password"}
EXTRAS=${EXTRAS:-""}

if [ ! -f "AMP_Linux_x86_64" ]; then
    echo "Creating $MODULE instance."
    cd /opt/amp
    ./ampinstmgr CreateInstance "$MODULE" instance \
        "$HOST" "$PORT" "$LICENCE" "$PASSWORD" \
        +Core.Login.Username "$USERNAME" \
        "$EXTRAS"
else
    cd /ampdata
    ./AMP_Linux_x86_64 +Core.AMP.LicenceKey "$LICENCE"
fi

cd /ampdata
exec ./AMP_Linux_x86_64
