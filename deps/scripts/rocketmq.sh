#!/usr/bin/env bash

set -e

version=4.3.1
fullName=rocketmq-all-$version-bin-release
shortName=rocketmq-$version

# Prepare workspace
buildPath=/tmp/rocketmq
rm -rf $buildPath
mkdir -p $buildPath
cd $buildPath

wget https://dist.apache.org/repos/dist/release/rocketmq/$version/$fullName.zip
unzip $fullName && mv $fullName $shortName

sed -i '' "s/-Xms4g -Xmx4g -Xmn2g -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=320m/-XX:MetaspaceSize=32m -XX:MaxMetaspaceSize=128m/g" $shortName/bin/runserver.sh

sed -i '' "s/mq_gc_%p.log/broker_gc.log/g" $shortName/bin/runbroker.sh
sed -i '' "s/-Xms8g -Xmx8g -Xmn4g/-XX:MetaspaceSize=32m -XX:MaxMetaspaceSize=128m/g" $shortName/bin/runbroker.sh
sed -i '' "/-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=30m/d" $shortName/bin/runbroker.sh
sed -i '' "/-XX:MaxDirectMemorySize=15g/d" $shortName/bin/runbroker.sh

sed -i '' -E 's/(<maxIndex>)[0-9]+/\15/g' $shortName/conf/logback_namesrv.xml $shortName/conf/logback_broker.xml
sed -i '' -E 's/(<maxFileSize>)[0-9]+/\110/g' $shortName/conf/logback_namesrv.xml $shortName/conf/logback_broker.xml

chmod +x $shortName/benchmark/*.sh
