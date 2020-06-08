#!/usr/bin/env bash

set -e

version=1.0.0
fullName=rocketmq-console-$version
servicePort=80

# Prepare workspace
../scripts/rocketmq-console.sh
cd /tmp/rocketmq-console

# Prepare entrypoint.sh
cat << ENTRY_SH > $fullName/entrypoint.sh
#!/usr/bin/env sh

set -e

JAVA_OPTS="\$JAVA_OPTS \
  -Duser.home=/$fullName \
  -Dserver.port=$servicePort \
  -Drocketmq.namesrv.addr=\$NAME_SERVERS \
  -Dcom.rocketmq.sendMessageWithVIPChannel=false \
  -Dlogging.config=/$fullName/conf/logback.xml
"

exec java \$JAVA_OPTS -jar /$fullName/lib/app.jar
ENTRY_SH

chmod +x $fullName/entrypoint.sh

docker build -t dockerhub.qingcloud.com/qingcloud/rocketmq-console:$version . -f-<< EOF
FROM openjdk:8u181-jre-alpine3.8

COPY $fullName/ /$fullName/

EXPOSE $servicePort

ENTRYPOINT ["/$fullName/entrypoint.sh"]
EOF

docker push dockerhub.qingcloud.com/qingcloud/rocketmq-console:$version
