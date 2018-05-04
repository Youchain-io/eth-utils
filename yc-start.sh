#!/bin/bash

root=$1
shift
network_id=$1
shift
N=$1
shift

if [ -z $root ] || [ -z $network_id ] || [ -z $N ]; then
    echo " USAGE:"
    echo "   ./yc-start.sh <root> <network_id> <N>"
    echo
    echo " ARGUMENTS:"
    echo "     <root>              root path of your nodes' data"
    echo "     <network_id>        network id"
    echo "     <N>                 number of nodes"
    echo
    exit 1
fi


PORT=30300
WS_SECRET=kscc

./gethcluster.sh $root $network_id $N 127.0.0.1 $*
./netstatconf.sh $N $network_id http://localhost:$PORT $WS_SECRET localhost > $root/$network_id/nodes.json
cd ../eth-net-intelligence-api
pm2 start $root/$network_id/nodes.json
cd ../eth-netstats
PORT=$PORT WS_SECRET=$WS_SECRET npm start > $root/$network_id/log/netstats.log 2>&1 &
cd ../eth-utils

