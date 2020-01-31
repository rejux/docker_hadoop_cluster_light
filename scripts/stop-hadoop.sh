#!/bin/bash

# STOP HADOOP

# $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh stop historyserver
$HADOOP_HOME/bin/mapred --daemon stop historyserver
$HADOOP_HOME/sbin/stop-yarn.sh
$HADOOP_HOME/sbin/stop-dfs.sh

tail -f /dev/null

