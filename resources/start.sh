#!/bin/bash

#关闭
echo "kill resources server"
ps -aux|grep 'ResourcesServer.js'|grep -v 'grep'|awk '{print $2}'|xargs kill -9

#启动
echo "start resources server"
nohup node ResourcesServer.js > /dev/null 2>&1 &