###################
##  Name Server  ##
###################
setEnvVar() {
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
}

initNode() {
  mkdir -p -m=766 /data/nameserver
  chown -R rocketmq:rocketmq /data/nameserver
  ln -s -f /opt/app/current/conf/caddy/index.html /data/index.html
  usermod -d /data/nameserver -u $(id -u rocketmq) rocketmq
  _initNode
}

readClusterListFromNameserver() {
  setEnvVar
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
