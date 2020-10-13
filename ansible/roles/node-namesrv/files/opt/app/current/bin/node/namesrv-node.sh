###################
##  Name Server  ##
###################

initNode() {
  mkdir -p -m=750 /data/nameserver
  chown -R rocketmq:svc /data/nameserver
  ln -s -f /opt/app/current/conf/caddy/index.html /data/nameserver/index.html
  _initNode
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
