#!/bin/bash
DATE=`date "+%a"`
DATADIR=$(cat backup.conf | grep 'DATADIR' | awk -F "=" '{print $2}')
BACKUPDIR=$(cat backup.conf | grep 'BACKUPDIR' | awk -F "=" '{print $2}')/${DATE}
NODEPORT=$(cat backup.conf | grep 'NODEPORT' | awk -F "=" '{print $2}')
NODEOSBINDIR=$(cat backup.conf | grep 'NODEOSBINDIR' | awk -F "=" '{print $2}')
if [ ! -d "$NODEOSBINDIR" ]; then
   echo Nodeos binary dir path not right. Please change it.
   exit 0
fi
if [ ! -d "$DATADIR" ]; then
   echo Nodeos datadir path not right. Please change it.
   exit 0
fi
PIDFILE=$(ls $DATADIR | grep nodeos.pid | wc -l)
NODEPID=$(netstat -tlpn 2>/dev/null | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b\:${NODEPORT} " | awk -F "LISTEN" '{print $2}' | awk -F "/" '{print $1}' | sed 's/ //g')
if [ -n "$NODEPID" ]; then
   echo nodepid = $NODEPID
   kill $NODEPID
   if [ "$PIDFILE" == "1" ]; then
      rm -r $DATADIR"/nodeos.pid"
   fi
   echo -ne "Stoping Nodeos"

        while true; do
            [ ! -d "/proc/$NODEPID/fd" ] && break
            echo -ne "."
            sleep 1
        done
   echo -ne "\rNodeos Stopped.    \n"
elif [ "$1" != "-w" ]
then
   echo Port $NODEPORT not listen. If you run script but node is not started type ./backup.sh -w
   exit 0
fi

mkdir $BACKUPDIR

if [ -d "$BACKUPDIR" ]; then
     cp -rf $DATADIR/state/ ${BACKUPDIR}/ && cp -rf $DATADIR/blocks/ ${BACKUPDIR}/
     echo -e "Starting Nodeos \n";
     ulimit -c unlimited
     ulimit -n 65535
     ulimit -s 64000
     $NODEOSBINDIR/nodeos/nodeos --data-dir $DATADIR --config-dir $DATADIR > $DATADIR/stdout.txt 2> $DATADIR/stderr.txt &  echo $! > $DATADIR/nodeos.pid
else
   echo $BACKUPDIR is not created. Check your permissions.
   exit 0
fi

