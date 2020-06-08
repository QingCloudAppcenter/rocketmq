#!/usr/bin/env bash

set -e

version=4.3.1
shortName=rocketmq-$version

# Prepare workspace
../scripts/rocketmq.sh

cd /tmp/rocketmq

docker build -t dockerhub.qingcloud.com/qingcloud/rocketmq:$version . -f- << EOF
FROM openjdk:8u181-jre-alpine3.8

COPY $shortName /$shortName
ENV PATH=\$PATH:/$shortName/bin

EXPOSE 9876 10909 10911

CMD ["mqnamesrv", "-n", "0.0.0.0:9876"]
EOF

docker push dockerhub.qingcloud.com/qingcloud/rocketmq:$version
