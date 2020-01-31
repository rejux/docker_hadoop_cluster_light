#!/bin/bash

echo "[INFO]"
echo "[INFO] ## ============================================== ##"
echo "[INFO] ## $(basename ${BASH_SOURCE[0]})"
echo "[INFO] ## ============================================== ##"
echo "[INFO]"

# globals

top_dir="${1}"

if [ -d "${top_dir}" -a \
    -f "${top_dir}/dockerfiles/Dockerfile-hadoop3-nn" -a \
    -f "${top_dir}/dockerfiles/Dockerfile-hadoop3-dn1" -a \
    -f "${top_dir}/dockerfiles/Dockerfile-hadoop3-dn2" ]; then

    	echo "[INFO] Arg1: ${top_dir} is correct"

else

    	echo "[ERROR]"
	echo "[ERROR] The Arg1: ${top_dir} is not valid. Abort!"
	echo "[ERROR] Usage: $(basename ${BASH_SOURCE[0]}) <TOP_DIR>"
	echo "[ERROR] Ex. : $(basename ${BASH_SOURCE[0]}) .."
	echo "[ERROR] Abort!"
	echo "[ERROR]"
	exit -1

fi

nn_image="hadoop3-nn"
images=(${nn_image} hadoop3-dn1 hadoop3-dn2)
images_inv=(hadoop3-dn1 hadoop3-dn2 ${nn_image})  # warning: put child before

echo "[INFO]"
echo "[INFO] Stop all running containers of images ${images_inv[@]}..."
echo "[INFO]"

echo
for image in ${images_inv[@]}; do
    for id in $(sudo docker ps --filter "name=$image" -q); do
        echo "[INFO] Stop container id = $id ..."
        docker rm -vf $id
    done
done

echo "[INFO]"
echo "[INFO] Remove the images and build new ones"
echo "[INFO]"

cd ${top_dir}

echo
for image in ${images[@]}; do

    echo "[INFO]"
    echo "[INFO] Build the image $image..."
    echo "[INFO]"

    docker build -f ./dockerfiles/Dockerfile-$image -t $image .
    error_code="${?}"

    if [ "${error_code}" == "0" ]; then

        echo "[INFO]"
        echo "[INFO] Image ${image} is successfully created. Done. "
        echo "[INFO] Cleaning the Docker registry by removing dangling images..."
        echo "[INFO]"

        [ ! -z "$(docker ps -aqf status=exited)" ] \
            && docker rm $(docker ps -aqf status=exited)

        [ ! -z "$(docker images -q -f dangling=true)" ] \
            && docker rmi $(docker images -q -f dangling=true)

        echo "[INFO]"
        echo "[INFO] ========================================================"
        echo "[INFO] You can quickly access the coantainer by running:"
        echo "[INFO] # docker run --rm -it ${image}"
        echo "[INFO] ========================================================"
        echo "[INFO]"

        echo "[INFO] Done."

    else

        echo "[ERROR]"
        echo "[ERROR] Something wrong. Failed with error code = ${error_code}. Abort!"
        echo "[ERROR]"
        exit ${error_code}

    fi

done

cd -

echo "[INFO]"
echo "[INFO] All containers are successfully built!"
echo "[INFO]"

exit 0

