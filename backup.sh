#!/bin/bash
DATE=`date "+%a"`
DATADIR=$(cat backup_uni.conf | grep 'DATADIR' | awk -F "=" '{print $2}')
BACKUPDIR=$(cat backup_uni.conf | grep 'BACKUPDIR' | awk -F "=" '{print $2}')
NODEPORT=$(cat backup_uni.conf | grep 'NODEPORT' | awk -F "=" '{print $2}')
NODEOSBINDIR=$(cat backup_uni.conf | grep 'NODEOSBINDIR' | awk -F "=" '{print $2}')
if [ ! -d "$NODEOSBINDIR" ]; then
   echo Nodeos binary dir path not right. Please change it.
   exit 0
fi
if [ ! -d "$DATADIR" ]; then
   echo Nodeos datadir path not right. Please change it.
   exit 0
fi
NODEPID=$(netstat -tlpn 2>/dev/null | grep "$NODEPORT" | awk -F "LISTEN" '{print $2}' | awk -F "/" '{print $1}' | sed 's/ //g')
if [ -n "$NODEPID" ]; then
   echo nodepid = $NODEPID
   kill $NODEPID
   echo -ne "Stoping Nodeos"

        while true; do
            [ ! -d "/proc/$NODEPID/fd" ] && break
            echo -ne "."
            sleep 1
        done
   echo -ne "\rNodeos Stopped.    \n"
else
   echo Port $NODEPORT not listen.
   exit 0
fi

mkdir $BACKUPDIR

if [ -d "$BACKUPDIR" ]; then
     cp -rf $DATADIR/state/ ${BACKUPDIR}/ && cp -rf $DATADIR/blocks/ ${BACKUPDIR}/
     echo -e "Starting Nodeos \n";
     ulimit -c unlimited
     ulimit -n 65535
     ulimit -s 64000
     $NODEOSBINDIR/nodeos/nodeos --data-dir $DATADIR --config-dir $DATADIR "$@" > $DATADIR/stdout.txt 2> $DATADIR/stderr.txt &  echo $! > $DATADIR/nodeos.pid
else
   echo $BACKUPDIR is not created. Check your permissions.
   exit 0
fi

