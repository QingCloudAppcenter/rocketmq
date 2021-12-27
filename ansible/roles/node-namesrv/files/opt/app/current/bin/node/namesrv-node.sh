###################
##  Name Server  ##
###################

initNode() {
  log "INFO: Application is about to initialize . "
  mkdir -p -m=750 /data/nameserver
  chown -R rocketmq:svc /data/nameserver
  mkdir -p /data/log/nameserver
  chmod 777 /data/log/nameserver
  ln -s -f /opt/app/current/conf/caddy/index.html /data/index.html
  _initNode
  log "INFO: Application initialization completed  . "
}

readClusterListFromNameserver() {
  export JAVA_HOME
  brokers="$(timeout -s SIGKILL 10s /opt/rocketmq/current/bin/mqadmin clusterList -n ${NAME_SERVER_LIST} 2>/dev/null \
              | awk 'NR > 1 { print $2,$3,$4 }' \
              | jq -R -c 'split(" ")' \
              | paste -s -d, -)"
  cat << BROKERS_LIST
{
  "labels": [ "brokerName", "brokerId", "brokerAddr" ],
  "data": [ ${brokers} ]
}
BROKERS_LIST
}

checkSvc() {
  checkActive ${1%%/*} || {
    log "INFO: Service '$1' is inactive."
    return $EC_CHECK_INACTIVE
  }
  local endpoints=$(echo $1 | awk -F/ '{print $3}')
  local endpoint; for endpoint in ${endpoints//,/ }; do
    checkEndpoint $endpoint || {
      log "WARN: Endpoint '$endpoint' is unreachable."
      return 0
    }
  done
}
