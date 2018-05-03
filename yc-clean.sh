# !/bin/bash

root=$1
shift
network_id=$1
shift

./yc-stop.sh
rm -rf $root/$network_id/*