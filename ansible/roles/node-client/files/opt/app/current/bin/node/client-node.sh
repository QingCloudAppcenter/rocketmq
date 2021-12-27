######################
##  RocketMQ Client ##
######################

initNode() {
  logger "Initializing client node..."
  echo -e "client\nclient\n" | adduser client > /dev/nul 2>&1 || echo "client:client" | chpasswd;
  mkdir -p -m=750 /data/console
  chown -R rocketmq:svc /data/console
  mkdir -p /data/log/console
  chmod 777 /data/log/console
  ln -s -f /opt/app/current/conf/caddy/index.html /data/index.html
  _initNode
  log "INFO: Application initialization completed  . "
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