#!/bin/bash

echo "[INFO]"
echo "[INFO] ## ============================================== ##"
echo "[INFO] ## $(basename ${BASH_SOURCE[0]})"
echo "[INFO] ## ============================================== ##"
echo "[INFO]"

# globals

network="hadoopnet"
subnet="173.18.0.0/16"

# main

docker network inspect ${network}

if [ $? == 0 ]; then

    echo "[WARNING]"
    echo "[WARNING] Network ${network} already exist. Abort!"
    echo "[WARNING]"

    exit 0

fi

echo "[INFO]"
echo "[INFO] (Re)Create the ${network} network..."
echo "[INFO]"

set -x
docker network create --subnet=${subnet} ${network}
set +x

echo "[INFO] Network ${network} successfully created: "
echo "[INFO]"

docker network inspect ${network}

echo "[INFO] Done."

exit 0


