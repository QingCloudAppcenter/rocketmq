
initNode() {
  mkdir -p -m=774 /data/console
  chown -R rocketmq:svc /data/console
  ln -s -f /opt/app/current/conf/caddy/index.html /data/console/index.html
  usermod -d /data/console -u $(id -u rocketmq) rocketmq
  _initNode
}
