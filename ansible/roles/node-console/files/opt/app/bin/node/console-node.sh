

initNode() {
  usermod -d /data/console -u $(id -u rocketmq) rocketmq
  _initNode
}
