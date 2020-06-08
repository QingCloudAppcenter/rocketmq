#!/usr/bin/env bash

set -e

version=1.0.0
fullName=rocketmq-console-$version
servicePort=80

# Prepare workspace
buildPath=/tmp/rocketmq-console
rm -rf $buildPath
mkdir -p $buildPath/$fullName/{lib,conf,logs}
cd $buildPath

wget https://github.com/apache/rocketmq-externals/archive/$fullName.tar.gz
tar xzf $fullName.tar.gz --strip-components 2 rocketmq-externals-rocketmq-console-${version}/rocketmq-console
mvn clean package -Dmaven.test.skip=true
cp target/rocketmq-console-ng-$version.jar $fullName/lib/app.jar
cp target/classes/logback.xml $fullName/conf/logback.xml
sed -i '' '/appender-ref ref="FILE"/d' $fullName/conf/logback.xml
