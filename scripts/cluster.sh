#!/bin/bash

echo "[INFO]"
echo "[INFO] ## ============================================== ##"
echo "[INFO] ## $(basename ${BASH_SOURCE[0]})"
echo "[INFO] ## ============================================== ##"
echo "[INFO]"

# globals

NN_RAM="4000m"
DN_RAM="8000m"

NN_CPUS="2"
DN_CPUS="4"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

network="hadoopnet"
nn_image="hadoop3-nn"
dn1_image="hadoop3-dn1"
dn2_image="hadoop3-dn2"

nn_container="${nn_image}"
dn1_container="${dn1_image}"
dn2_container="${dn2_image}"

nn_volume="/data/hadoop_store/hdfs/namenode"
dn_volume="/data/hadoop_store/hdfs/datanode"
dn1_volume="/data/hadoop_store/hdfs/datanode1"
dn2_volume="/data/hadoop_store/hdfs/datanode2"

dn1_ip="173.18.0.11"
dn2_ip="173.18.0.12"
nn_ip="173.18.0.13"

###########################
## stop_cluster
###########################

# Stop a running cluster

function stop_cluster {

    echo "[INFO]"
    echo "[INFO] Stopping datanode ${dn1_container} ..."
    echo "[INFO]"

    is_running_dn1=$(docker ps | grep "${dn1_container}")

    if [ ! -z "${is_running_dn1}" -a ${?} == 0 ]; then

        echo "[INFO] DN1 is running! Stopping container..."
        docker stop ${dn1_container}
        echo "[INFO] Done."

    else
        echo "[WARN] DN1 is not running!"
    fi

    echo "[INFO]"
    echo "[INFO] Stopping datanode ${dn2_container} ..."
    echo "[INFO]"

    is_running_dn2=$(docker ps | grep "${dn2_container}")

    if [ ! -z "${is_running_dn2}" -a ${?} == 0 ]; then

        echo "[INFO] DN2 is running! Stopping container..."
        docker stop ${dn2_container}
        echo "[INFO] Done."

    else
        echo "[WARN] DN2 is not running!"
    fi

    echo "[INFO]"
    echo "[INFO] Stopping namenode ${nn_container} ..."
    echo "[INFO]"

    is_running_nn=$(docker ps | grep "${nn_container}")

    if [ ! -z "${is_running_nn}" -a ${?} == 0 ]; then

        echo "[INFO] NN is running! Stopping container..."
        docker stop ${nn_container}
        echo "[INFO] Done."

    else
        echo "[WARN] NN is not running!"
    fi

}


###########################
## start_cluster
###########################

# Run an already existing cluster
# without (re)deployment

function start_cluster {


    echo "[INFO]"
    echo "[INFO] Running namenode ${nn_container} ..."
    echo "[INFO]"

    set -x
    docker run --rm -d -P -it --net ${network} \
        --ip ${nn_ip} \
        --hostname ${nn_container} \
        --add-host ${dn1_container}:${dn1_ip} \
        --add-host ${dn2_container}:${dn2_ip} \
        -v ${nn_volume}:${nn_volume} \
        -v ${dn_volume}:${dn_volume} \
        --name ${nn_container} ${nn_image}
    set +x

    echo "[INFO]"
    echo "[INFO] Running datanode ${dn1_container} ..."
    echo "[INFO]"

    set -x
    docker run --rm -d -P -it --net ${network} \
        --ip ${dn1_ip} \
        --hostname ${dn1_container} \
        --add-host ${nn_container}:${nn_ip} \
        --add-host ${dn2_container}:${dn2_ip} \
        -v ${dn1_volume}:${dn1_volume} \
        --name ${dn1_container} ${dn1_image}
    set +x

    echo "[INFO]"
    echo "[INFO] Running datanode ${dn2_image} ..."
    echo "[INFO]"

    set -x
    docker run --rm -d -P -it --net ${network} \
        --ip ${dn2_ip} \
        --hostname ${dn2_container} \
        --add-host ${nn_container}:${nn_ip} \
        --add-host ${dn1_container}:${dn1_ip} \
        -v ${dn2_volume}:${dn2_volume} \
        --name ${dn2_container} ${dn2_image}
    set +x

}

###########################
## start_services
###########################

function start_services {

    is_running_nn=$(docker ps | grep "${nn_container}")

    if [ -z "${is_running_nn}" -o ${?} != 0 ]; then

        echo "[WARN]"
        echo "[WARN] Container ${nn_container} (e.g. Namenode) is not running! Services cannot be started."
        echo "[WARN] First start the cluster by running the start_cluster option, then after the start_services can be used."
        echo "[WARN] Abort!"
        echo "[WARN]"

        exit -1

    fi

    # echo "[INFO]"
    # echo "[INFO] Starting the cluster..."
    # echo "[INFO]"

    # docker start ${nn_container} ${dn1_container} ${dn2_container}
    # sleep 5

    echo "[INFO]"
    echo "[INFO] (start_services) Starting HDFS on Namenode..."
    echo "[INFO]"

    docker exec -u hadoop -it ${nn_container} /opt/hadoop/sbin/start-dfs.sh
    sleep 5

    echo "[INFO]"
    echo "[INFO] (start_services) Starting Yarn on Namenode..."
    echo "[INFO]"

    docker exec -u hadoop -d ${nn_container} /opt/hadoop/sbin/start-yarn.sh
    sleep 5

    echo "[INFO]"
    echo "[INFO] (start_services) Starting MapReduce daemon..."
    echo "[INFO]"

    docker exec -u hadoop -d ${nn_container} /opt/hadoop/bin/mapred --daemon start historyserver
    sleep 5


    # echo "[INFO]"
    # echo "[INFO] >>> Starting Spark on all nodes..."
    # echo "[INFO]"

    # docker exec -u hadoop -d ${nn_container} /home/hadoop/bin/sparkcmd.sh start
    # docker exec -u hadoop -d ${dn1_container} /home/hadoop/bin/sparkcmd.sh start
    # docker exec -u hadoop -d ${dn2_container} /home/hadoop/bin/sparkcmd.sh start

    echo "[INFO]"
    echo "[INFO] The cluster is started and you can consult the UI using the following URLs: "
    echo "[INFO] + HDFS GUI admin console: http://${nn_ip}:9870/"
    echo "[INFO] + YARN GUI admin console: http://${nn_ip}:8088/"
    echo "[INFO]"
    echo "[WARN] Warning: If you live behind a proxy, please add an exception for the IP of of"
    echo "[WARN] the container in your browser to access the URL."
    echo "[INFO]"

}

###########################
## stop_services
###########################

function stop_services {

    is_running_nn=$(docker ps | grep "${nn_container}")

    if [ -z "${is_running_nn}" -o ${?} != 0 ]; then

        echo "[WARN]"
        echo "[WARN] Container ${nn_container} (e.g. Namenode) is not running! Services are already stopped."
        echo "[WARN]"

        exit -2

    fi


    # docker exec -u hadoop -d ${dn1_container} /home/hadoop/bin/sparkcmd.sh stop
    # docker exec -u hadoop -d ${dn2_container} /home/hadoop/bin/sparkcmd.sh stop
    # docker exec -u hadoop -d ${nn_container} /home/hadoop/bin/sparkcmd.sh stop

    echo "[INFO]"
    echo "[INFO] (stop_services) Stopping MapReduce daemon..."
    echo "[INFO]"

    docker exec -u hadoop -d ${nn_container} /opt/hadoop/bin/mapred --daemon stop historyserver
    sleep 5

    echo "[INFO]"
    echo "[INFO] (stop_services) Stopping Yarn on Namenode..."
    echo "[INFO]"

    docker exec -u hadoop -d ${nn_container} /opt/hadoop/sbin/stop-yarn.sh
    sleep 5

    echo "[INFO]"
    echo "[INFO] (stop_services) Stopping HDFS on Namenode..."
    echo "[INFO]"

    docker exec -u hadoop -it ${nn_container} /opt/hadoop/sbin/stop-dfs.sh
    sleep 5

}



###########################
## usage
###########################

function usage {

    echo "[INFO]"
    echo "[INFO] Usage: cluster.sh run|start|stop"
    echo "[INFO]    start_cluster   - run the cluster without starting the services"
    echo "[INFO]    stop_cluster    - stop properly the cluster by starting first the services"
    echo "[INFO]    start_services  - start the Hadoop services on a running cluster"
    echo "[INFO]    stop_services   - stop the Hadoop services on a running cluster"
    echo "[INFO]"

}



# function deploy_cluster {

    # start_cluster

    # 3 nodes
    # no more datanode0:
    # -v /home/hadoop_store/hdfs/datanode0:/home/hadoop_store/hdfs/datanode

#     echo "[INFO] >> Starting nodes master and worker nodes ..."
#
#     docker run --rm -d --net ${hadoopnet} --ip 173.18.1.1 --hostname ${nn_image} --add-host ${dn1_image}:173.18.1.2 --add-host ${dn2_image}:173.18.1.3 \
#         --memory="${NN_RAM}" --cpus="${NN_CPUS}" \
#         -v /home/hadoop_store/hdfs/namenode:/home/hadoop_store/hdfs/namenode \
#         -v /home/hadoop_store/exchanges/deploy:/home/hadoop_store/exchanges/deploy \
#         -v /home/hadoop_store/exchanges/data:/home/hadoop_store/exchanges/data \
#         --name ${nn_image} -it namenodebase
#
#     docker run --rm -d --net ${hadoopnet} --ip 173.18.1.2 --hostname ${dn1_image}  --add-host ${nn_image}:173.18.1.1 --add-host ${dn2_image}:173.18.1.3 \
#         --memory="${DN_RAM}" --cpus="${DN_CPUS}" \
#         -v /home/hadoop_store/hdfs/datanode1:/home/hadoop_store/hdfs/datanode \
#         --name ${dn1_image} -it datanodebase
#
#     docker run --rm -d --net ${hadoopnet} --ip 173.18.1.3 --hostname ${dn2_image}  --add-host ${nn_image}:173.18.1.1 --add-host ${dn1_image}:173.18.1.2 \
#         --memory="${DN_RAM}" --cpus="${DN_CPUS}" \
#         -v /home/hadoop_store/hdfs/datanode2:/home/hadoop_store/hdfs/datanode \
#         --name ${dn2_image} -it datanodebase
#

##
## main
##

# TODO Replace the following by a case...esac

if [[ $1 = "start_cluster" ]]; then
    start_cluster
    # startServices
    exit 0
fi

if [[ $1 = "stop_cluster" ]]; then
    stop_cluster
    # stopServices
    exit 0
fi

if [[ $1 = "start_services" ]]; then
    start_services
    exit 0
fi

if [[ $1 = "stop_services" ]]; then
    stop_services
    exit 0
fi


usage

exit 0

