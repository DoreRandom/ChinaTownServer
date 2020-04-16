#!/bin/bash

FLAG=$1
if [ -z $FLAG ] ; then
    GFLAG=undefine_gs
fi
./shell/gs_kill.sh $GFLAG
./shell/gs_run.sh $GFLAG