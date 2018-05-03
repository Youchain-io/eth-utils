# !/bin/bash

root=$1
shift
network_id=$1
shift
nodes=$1
shift

PORT=30300
WS_SECRET=kscc

./gethcluster.sh $root $network_id $nodes 127.0.0.1
./netstatconf.sh $nodes $network_id http://localhost:$PORT $WS_SECRET localhost > $root/$network_id/nodes.json
cd ../eth-net-intelligence-api
pm2 start $root/$network_id/nodes.json
cd ../eth-netstats
PORT=$PORT WS_SECRET=$WS_SECRET npm start > $root/$network_id/log/netstats.log 2>&1 &
cd ../eth-utils

