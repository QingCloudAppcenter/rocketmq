######################
##  RocketMQ Client ##
######################

initNode() {
  logger "Initializing client node..."
  export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
  export PATH="$JAVA_HOME/bin:$PATH";
  echo 'ubuntu:p12cHANgepwD' | chpasswd
  deluser ubuntu sudo
}
