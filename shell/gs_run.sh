#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    FLAG=undefine_gs
fi

ps aux|grep 'skynet' | grep $FLAG |grep -v 'grep' 1>/dev/null
if [ $? -eq 0 ] ; then
    echo 'exsit process skynet, skip start!'
    exit 2
fi

#上次的日志保存
LOG_BAK_ROUT="bak"
if [ -f ./log/gs.log ]; then
    echo 'backup log'
    if [ ! -d ./log/$LOG_BAK_ROUT ]; then
        mkdir ./log/$LOG_BAK_ROUT
    fi
    dict=`pwd`
    cd ./log/$LOG_BAK_ROUT
    ls -t | awk '{if(NR>=10){print $0}}' | xargs rm -f
    cd $dict
    mv ./log/gs.log ./log/$LOG_BAK_ROUT/gs_`date +%Y%m%d-%H%M%S`.log
fi

#启动
echo "starting server"
nohup ./skynet/skynet ./config/gs_config.lua $FLAG > log/gs.log 2>&1 &