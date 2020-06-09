

initNode() {
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
  usermod -d /data/console -u $(id -u rocketmq) rocketmq
  _initNode
}
