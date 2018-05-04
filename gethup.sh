#!/bin/bash

root=$1
shift
network_id=$1
shift
id=$1
shift
prt=$1
shift

if [ -z $root ] || [ -z $network_id ] || [ -z $id ] || [ -z $prt ]; then
    echo " USAGE:"
    echo "   ./gethup.sh <root> <network_id> <id> <prt>"
    echo
    echo " ARGUMENTS:"
    echo "     <root>              root path of your nodes' data"
    echo "     <network_id>        network id"
    echo "     <id>                double digit instance id like 01 02"
    echo "     <prt>               double digit port like 02 03"
    echo
    exit 1
fi


# logs are output to a date-tagged file for each run , while a link is
# created to the latest, so that monitoring be easier with the same filename
# TODO: use this if GETH not set
GETH=geth

# geth CLI params       e.g., (id=03, run=09)
datetag=`date "+%c%y%m%d-%H%M%S"|cut -d ' ' -f 5`
datadir=$root/data/$id        # /tmp/eth/03
log=$root/log/$id.$datetag.log     # /tmp/eth/03.09.log
linklog=$root/log/$id.current.log     # /tmp/eth/03.09.log
stablelog=$root/log/$id.log     # /tmp/eth/03.09.log
password=$id            # 03
port=303$prt              # 30304
rpcport=81$prt            # 8104
bootnode=$(cat $root/bootnode)

mkdir -p $root/data
mkdir -p $root/log
ln -sf "$log" "$linklog"
# if we do not have an account, create one
# will not prompt for password, we use the double digit instance id as passwd
# NEVER EVER USE THESE ACCOUNTS FOR INTERACTING WITH A LIVE CHAIN
if [ ! -d "$root/keystore/$id" ]; then
      echo create an account with password $id [DO NOT EVER USE THIS ON LIVE]
      mkdir -p $root/keystore/$id
      $GETH --datadir $datadir --password <(echo -n $id) account new
      # create account with password 00, 01, ...
      # note that the account key will be stored also separately outside
      # datadir
      # this way you can safely clear the data directory and still keep your key
      # under `<rootdir>/keystore/id

      cp -R "$datadir/keystore" $root/keystore/$id
fi

# echo "copying keys $root/keystore/$id $datadir/keystore"
# ls $root/keystore/$id/keystore/ $datadir/keystore

# mkdir -p $datadir/keystore
# if [ ! -d "$datadir/keystore" ]; then
echo "copying keys $root/keystore/$id $datadir/keystore"
cp -R $root/keystore/$id/keystore/ $datadir/keystore/
# fi

BZZKEY=`$GETH --datadir=$datadir account list|head -n1|perl -ne '/([a-f0-9]{40})/ && print $1'`

# bring up node `id` (double digit)
# - using <rootdir>/<id>
# - listening on port 303port, (like 30300, 30301, ...)
# - with the account unlocked
# - launching json-rpc server on port 81port (like 8100, 8101, 8102, ...)
echo "$GETH --datadir $datadir \
    --networkid $network_id \
    --port $port \
    --unlock $BZZKEY \
    --password <(echo -n $id) \
    --rpc --rpcport $rpcport \
    --rpccorsdomain '*' \
    --bootnodes \"$bootnode\" \
    --rpcapi \"db,eth,net,web3\" $* \
    2>&1 | tee \"$stablelog\" > \"$log\" &  # comment out if you pipe it to a tty etc."

$GETH --datadir $datadir \
    --networkid $network_id \
    --port $port \
    --unlock $BZZKEY \
    --password <(echo -n $id) \
    --rpc --rpcport $rpcport \
    --rpccorsdomain '*' \
    --bootnodes "$bootnode" \
    --rpcapi "db,eth,net,web3" $* \
    2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.

# to bring up logs, uncomment
# tail -f $log
