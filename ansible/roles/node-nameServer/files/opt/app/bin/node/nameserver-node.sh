###################
##  Name Server  ##
###################

initNode() {
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
  usermod -d /data/console -u $(id -u rocketmq) rocketmq
  _initNode
}

readClusterListFromNameserver() {
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
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
