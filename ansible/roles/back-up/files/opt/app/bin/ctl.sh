#!/usr/bin/env bash

set -e

. /etc/profile.d/rocketmq.sh

nodeRole=${NODE_ROLE%-replica}
[[ ",$2," =~ ",$nodeRole," ]] || exit 0

##############
##  Common  ##
##############

# Usage allocation:
# -  20M  /dev/shm JVM GC logs
# -  32M           Metaspace
# -  16M           G1GC Heap Region
calcMaxMemorySize() {
  maxFree=$(free -m | awk '$1 ~ /^Mem:/ {print $4+$6-90}')
  [ $maxFree -lt 0 ] && echo 20 || echo ${maxFree}
}

checkPort() {
  nc -vz -w3 localhost $1
}

checkService() {
  systemctl is-active --quiet $1
}

stopService() {
  checkService $1 && systemctl stop $1 || true
}

###################
##  Name Server  ##
###################

startNameserver() {
  maxFree=$(calcMaxMemorySize)
  maxHeapSize=$[maxFree/2]m
  maxEdenSize=$[maxFree/4]m
  jvmFlags="-Duser.home=/data/nameserver -Xms${maxHeapSize} -Xmx${maxHeapSize} -Xmn${maxEdenSize} -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=4 -XX:GCLogFileSize=5m"
  cat << NAMESERVER_ENV > /opt/app/conf/nameserver/nameserver.env
ROCKETMQ_HOME=$ROCKETMQ_HOME
JAVA_HOME=$JAVA_HOME
JAVA_OPT='$jvmFlags'
NAMESERVER_ENV

  systemctl start rocketmq-nameserver
}

stopNameserver() {
  stopService rocketmq-nameserver
}

restartNameserver() {
  logger "Restarting name server..."
  stopNameserver
  startNameserver
}

checkNameserver() {
  checkService rocketmq-nameserver && checkPort $NAMESERVER_PORT
}

readClusterListFromNameserver() {
  brokers=$(/opt/apache-rocketmq/current/bin/mqadmin clusterList 2>/dev/null | awk 'NR > 1 { print $2,$3,$4 }' | jq -R -c 'split(" ")' | paste -s -d, -)
  cat << BROKERS_LIST
{
  "labels": [ "brokerName", "brokerId", "brokerAddr" ],
  "data": [ $brokers ]
}
BROKERS_LIST
}

##############
##  Broker  ##
##############

brokerDataDir=/data/broker

initBroker() {
  # Fix permissions for attached volume.
  chown -R rocketmq.root $brokerDataDir
  chmod -R u=rwx,g=rx,o= $brokerDataDir
}

startBroker() {
  maxFree=$(calcMaxMemorySize)
  maxHeapSize=$[maxFree/3]m
  maxEdenSize=$[maxFree/3]m
  maxDirectMemorySize=$[maxFree/3]m
  jvmFlags="-Duser.home=$brokerDataDir -Xms${maxHeapSize} -Xmx${maxHeapSize} -Xmn${maxEdenSize} -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=4 -XX:GCLogFileSize=5m"
  cat << BROKER_ENV > /opt/app/conf/broker/broker.env
ROCKETMQ_HOME=$ROCKETMQ_HOME
JAVA_HOME=$JAVA_HOME
JAVA_OPT='$jvmFlags'
BROKER_ENV

  systemctl start rocketmq-broker
}

stopBroker() {
  stopService rocketmq-broker
}

restartBroker() {
  logger "Restarting broker..."
  stopBroker
  startBroker
}

checkBroker() {
  checkService rocketmq-broker && checkPort $BROKER_PORT
}

metricsFile=/tmp/rocketmq-metrics.json

measureBroker() {
  [ -f "$metricsFile" ] && cat $metricsFile || echo '{}'

  [[ ( ! -f $metricsFile ) || ( `stat --format %Y $metricsFile` -lt $((`date +%s`  - 19)) ) ]] && generateBrokerMetrics &
}

metricsKeys="
putTps
getFoundTps
getMissTps
getTotalTps
getTransferedTps
msgGetTotalTodayNow
msgPutTotalTodayNow
msgGetTotalTodayMorning
msgPutTotalTodayMorning
putMessageAverageSize
"
filter="stub"
for k in $metricsKeys; do
  filter="$filter|$k"
done
generateBrokerMetrics() {
  touch $metricsFile

  broker="localhost:$BROKER_PORT"

  metrics=$(/opt/apache-rocketmq/current/bin/mqadmin brokerStatus -b $broker |& grep -E "^($filter)" | awk '{print $1, $3}')

  putTps=$(echo "$metrics" | awk '$1=="putTps" {printf("%d", $2*1000)}')
  getFoundTps=$(echo "$metrics" | awk '$1=="getFoundTps" {printf("%d", $2*1000)}')
  getMissTps=$(echo "$metrics" | awk '$1=="getMissTps" {printf("%d", $2*1000)}')
  getTotalTps=$(echo "$metrics" | awk '$1=="getTotalTps" {printf("%d", $2*1000)}')
  getTransferedTps=$(echo "$metrics" | awk '$1=="getTransferedTps" {printf("%d", $2*1000)}')
  getCountToday=$(echo "$metrics" | awk '/msgGetTotalTodayNow/ {LATTER=$2} /msgGetTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  putCountToday=$(echo "$metrics" | awk '/msgPutTotalTodayNow/ {LATTER=$2} /msgPutTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  msgAvgSize=$(echo "$metrics" | awk '$1=="putMessageAverageSize" {printf("%d", $2/8*100)}')

  cat << METRICS_FILE > $metricsFile
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

#######################
##  RocketMQ Console ##
#######################

consoleVersion=1.0.0
consoleName=rocketmq-console
consolePort=8080
consoleHome=$consoleName-$consoleVersion

startConsole() {
  maxFree=$(calcMaxMemorySize)
  maxHeapSize=$[maxFree/2]m
  cat << CONSOLE_ENV > /opt/app/conf/console/console.env
JAVA_OPT="-Duser.home=/data/console \
  -Xms${maxHeapSize} -Xmx${maxHeapSize} \
  -Drocketmq.namesrv.addr=$NAMESRV_ADDR \
  -Dcom.rocketmq.sendMessageWithVIPChannel=false \
  -Dlogging.config=/opt/app/conf/console/logback.xml \
  -Xloggc:/dev/shm/console_gc_%p.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=4 -XX:GCLogFileSize=5m"
CONSOLE_ENV

  systemctl start rocketmq-console
}

stopConsole() {
  stopService rocketmq-console
}

restartConsole() {
  logger "Restarting console..."
  stopConsole
  startConsole
}

checkConsole() {
  checkService rocketmq-console && checkPort $consolePort
}

######################
##  RocketMQ Client ##
######################

initClient() {
  logger "Initializing client node..."
  echo 'ubuntu:p12cHANgepwD' | chpasswd
  deluser ubuntu sudo
}

# Start executing.
"$1${nodeRole^}${3^}"
