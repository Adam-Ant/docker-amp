#!/bin/sh
set -e

randstr () { tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w $1 | head -n 1; }

if [ -z ${MODULE} ]; then echo "Error: The module name must be specified in the MODULE enviroment variable"; exit 1; fi
if [ -z ${LICENCE} ]; then echo "Error: A licence for AMP from cubecoders.com is required and must be specified in the environment variables"; exit 1; fi

if [ "$PASSWORD" == "changeme" ]; then
    export PASSWORD="$(randstr 8)"
    >&2 printf "[Info] The PASSWORD for the admin user is '%s'\n\n" "$PASSWORD"
fi

if [ ! -f "AMP_Linux_x86_64" ]; then
    >&2 echo "[Info] Creating $MODULE instance."
    ampinstmgr CreateInstance "$MODULE" instance \
        "$HOST" "$PORT" "$LICENCE" "$PASSWORD" \
        +Core.Login.Username "$USERNAME" \
        $EXTRAS
else
    cd /ampdata
    ./AMP_Linux_x86_64 +Core.AMP.LicenceKey "$LICENCE"
fi

cd /ampdata
exec ./AMP_Linux_x86_64
