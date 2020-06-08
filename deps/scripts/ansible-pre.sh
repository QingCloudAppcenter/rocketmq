#!/usr/bin/env bash

set -e

baseDir=$(dirname "$0")
destDir="$baseDir/../../ansible/files/opt"

version=4.3.1
dest="$destDir/apache-rocketmq"
rm -rf $dest && mkdir -p $dest && cp -r /tmp/rocketmq/rocketmq-$version $dest/$version

consoleVersion=1.0.0
dest="$destDir/apache-rocketmq-console"
rm -rf $dest && mkdir -p $dest && cp -r /tmp/rocketmq-console/rocketmq-console-$consoleVersion $dest/$consoleVersion
