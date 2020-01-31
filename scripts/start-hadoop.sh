#!/bin/bash

/etc/init.d/ssh start

# START HADOOP
##############

$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh
$HADOOP_HOME/bin/mapred --daemon start historyserver
# $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

# START HUE
###########
# sleep 20
# /opt/hue/build/env/bin/supervisor &

tail -f /dev/null

