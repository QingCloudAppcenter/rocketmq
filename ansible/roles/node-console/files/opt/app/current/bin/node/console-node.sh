
initNode() {
  mkdir -p -m=766 /data/console
  chown -R rocketmq:rocketmq /data/console
  ln -s -f /opt/app/current/conf/caddy/index.html /data/console/index.html
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
  usermod -d /data/console -u $(id -u rocketmq) rocketmq
  _initNode
}
