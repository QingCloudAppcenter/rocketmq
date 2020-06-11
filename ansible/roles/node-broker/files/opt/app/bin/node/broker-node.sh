#!/usr/bin/env bash

set -e


##############
##  Broker  ##
##############

brokerDataDir="/data/broker"

initNode() {
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
  usermod -d /data/broker -u $(id -u rocketmq) rocketmq
  # Fix permissions for attached volume.
  chown -R rocketmq.rocketmq ${brokerDataDir}
  chmod -R u=rwx,g=rx,o= ${brokerDataDir}
  _initNode
}

measure() {
  local filter metrics putTps getFoundTps getMissTps getTotalTps;
  local getTransferedTps getCountToday putCountToday msgAvgSize;
  filter="stub|putTps|getFoundTps|getMissTps|getTotalTps|getTransferedTps|msgGetTotalTodayNow|msgPutTotalTodayNow|msgGetTotalTodayMorning|msgPutTotalTodayMorning|putMessageAverageSize" ;
  metrics=$(timeout -s SIGKILL 6s /opt/rocketmq/current/bin/mqadmin brokerStatus -b "localhost:${BROKER_PORT:-10911}" |& grep -E "^($filter)" | awk '{print $1, $3}')
  putTps=$(echo "$metrics" | awk '$1=="putTps" {printf("%d", $2*1000)}')
  getFoundTps=$(echo "$metrics" | awk '$1=="getFoundTps" {printf("%d", $2*1000)}')
  getMissTps=$(echo "$metrics" | awk '$1=="getMissTps" {printf("%d", $2*1000)}')
  getTotalTps=$(echo "$metrics" | awk '$1=="getTotalTps" {printf("%d", $2*1000)}')
  getTransferedTps=$(echo "$metrics" | awk '$1=="getTransferedTps" {printf("%d", $2*1000)}')
  getCountToday=$(echo "$metrics" | awk '/msgGetTotalTodayNow/ {LATTER=$2} /msgGetTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  putCountToday=$(echo "$metrics" | awk '/msgPutTotalTodayNow/ {LATTER=$2} /msgPutTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  msgAvgSize=$(echo "$metrics" | awk '$1=="putMessageAverageSize" {printf("%d", $2/8*100)}')

  cat << METRICS_FILE
{
  "putTps": ${putTps:-0},
  "getFoundTps": ${getFoundTps:-0},
  "getMissTps": ${getMissTps:-0},
  "getTotalTps": ${getTotalTps:-0},
  "getTransferedTps": ${getTransferedTps:-0},
  "getCountToday": ${getCountToday:-0},
  "putCountToday": ${putCountToday:-0},
  "msgAvgSize": ${msgAvgSize:-0}
}
METRICS_FILE
}