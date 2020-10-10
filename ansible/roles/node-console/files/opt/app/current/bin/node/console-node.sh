
initNode() {
  mkdir -p -m=750 /data/console
  chown -R rocketmq:svc /data/console
  ln -s -f /opt/app/current/conf/caddy/index.html /data/console/index.html
  _initNode
}
