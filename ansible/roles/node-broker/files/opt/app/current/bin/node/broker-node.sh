##############
##  Broker  ##
##############
# Error codes
EC_INSUFFICIENT_VOLUME=230
EC_UNHEALTHY=240

initNode() {
  # Fix permissions for attached volume.
  chown -R rocketmq.svc ${DATA_MOUNTS}
  chmod u=rwx,g=rx,o=r ${DATA_MOUNTS}
  ln -s -f /opt/app/current/conf/caddy/index.html ${DATA_MOUNTS}/index.html
  _initNode
}

metricsFile="/data/broker/rocketmq-metrics.json"
measure() {
  [[ -f "${metricsFile}" ]] && cat ${metricsFile} || echo '{}'

  [[ ( ! -f ${metricsFile} ) || ( `stat --format %Y ${metricsFile}` -lt $((`date +%s`  - 19)) ) ]] && generateBrokerMetrics &
}

generateBrokerMetrics() {
  local filter metrics putTps getFoundTps getMissTps getTotalTps;
  local getTransferedTps getCountToday putCountToday msgAvgSize;
  filter="stub|putTps|getFoundTps|getMissTps|getTotalTps|getTransferedTps|msgGetTotalTodayNow|msgPutTotalTodayNow|msgGetTotalTodayMorning|msgPutTotalTodayMorning|putMessageAverageSize" ;
  metrics=$(timeout -s SIGKILL 30s /opt/rocketmq/current/bin/mqadmin brokerStatus -b "localhost:${BROKER_PORT:-10911}" |& grep -E "^($filter)" | awk '{print $1, $3}')
  putTps=$(echo "$metrics" | awk '$1=="putTps" {printf("%d", $2*1000)}')
  getFoundTps=$(echo "$metrics" | awk '$1=="getFoundTps" {printf("%d", $2*1000)}')
  getMissTps=$(echo "$metrics" | awk '$1=="getMissTps" {printf("%d", $2*1000)}')
  getTotalTps=$(echo "$metrics" | awk '$1=="getTotalTps" {printf("%d", $2*1000)}')
  getTransferedTps=$(echo "$metrics" | awk '$1=="getTransferedTps" {printf("%d", $2*1000)}')
  getCountToday=$(echo "$metrics" | awk '/msgGetTotalTodayNow/ {LATTER=$2} /msgGetTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  putCountToday=$(echo "$metrics" | awk '/msgPutTotalTodayNow/ {LATTER=$2} /msgPutTotalTodayMorning/ {FORMER=$2} END {printf("%d", LATTER - FORMER)}')
  msgAvgSize=$(echo "$metrics" | awk '$1=="putMessageAverageSize" {printf("%d", $2/8*100)}')

  cat > ${metricsFile}  << METRICS_FILE
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
