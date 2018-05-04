#!/bin/bash

root=$1
shift
network_id=$1
dir=$root/$network_id
mkdir -p $dir/data
mkdir -p $dir/log
shift
N=$1
shift
ip_addr=$1
shift

if [ -z $root ] || [ -z $network_id ] || [ -z $N ] || [ -z $ip_addr ]; then
    echo " USAGE:"
    echo "   ./gethcluster.sh <root> <network_id> <nodes>"
    echo
    echo " ARGUMENTS:"
    echo "     <root>              root path of your nodes' data"
    echo "     <network_id>        network id"
    echo "     <N>                 number of nodes"
    echo "     <ip_addr>           local IP address"
    echo
    exit 1
fi


GETH=geth


if [ ! -f "$dir/genesis.json"  ]; then

    echo "setting up genesis"
    echo -e "{ \n\
    \"config\": { \n\
        \"chainId\": $network_id, \n\
        \"homesteadBlock\": 0, \n\
        \"eip155Block\": 0, \n\
        \"eip158Block\": 0 \n\
    }, \n\
    \"alloc\": {}, \n\
    \"coinbase\": \"0x0000000000000000000000000000000000000000\", \n\
    \"difficulty\": \"0x400\", \n\
    \"extraData\": \"\", \n\
    \"gasLimit\": \"0x47E7C4\", \n\
    \"nonce\": \"0x0000000000000042\", \n\
    \"mixhash\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \n\
    \"parentHash\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \n\
    \"timestamp\": \"0x0\" \n\
}" >> $dir/genesis.json
fi

if [ ! -f "$dir/bootnode"  ]; then

    echo "setting up bootnode"
    cmd="./bootnode -genkey $dir/bootnode.key"
    echo $cmd
    bash -c "$cmd"
    echo "launching bootnode"
    cmd="./bootnode -nodekey $dir/bootnode.key"
    echo $cmd
    bash -c "$cmd" 2>&1 |tee $dir/log/bootnode.log &
    sleep 1
    echo "getting bootnode enode"
    cat $dir/log/bootnode.log 2>/dev/null |grep enode |perl -pe "s/\[\:\:\]/$ip_addr/g" |perl -pe 's/.+self=(.+)/$1/' |tee $dir/bootnode
    bootnode=$(cat $dir/bootnode)
fi

if [ ! -f "$dir/nodes"  ]; then

    echo -n "[" >> $dir/nodes
    for ((i=0;i<N;++i)); do
        id=`printf "%02d" $((i+1))`
        port=`printf "%02d" $((i+2))`

        eth="$GETH --datadir $dir/data/$id --port 303$port --networkid $network_id"
        echo "initializing node"
        cmd="$eth init $dir/genesis.json"
        bash -c "$cmd" 2>&1
        echo "getting enode for instance $id ($((i+1))/$N)"
        cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
        echo $cmd
        bash -c "$cmd" 2>/dev/null |grep enode |perl -pe "s/\[\:\:\]/$ip_addr/g" |perl -pe "s/^/\"/; s/\s*$/\"/;" |tee >> $dir/nodes
        if ((i<N-1)); then
            echo "," >> $dir/nodes
        fi

        echo "creating attach script"
        echo "$eth $* attach" >> $dir/attach-$id.sh
        bash -c "chmod +x $dir/attach-$id.sh"
    done
    echo "]" >> $dir/nodes
fi

for ((i=0;i<N;++i)); do
    id=`printf "%02d" $((i+1))`
    port=`printf "%02d" $((i+2))`

    mkdir -p $dir/data/$id
    echo "launching node $id ($((i+1))/$N) ---> tail-f $dir/log/$id.log"
    eth="bash ./gethup.sh $dir $network_id $id $port"
    cmd="$eth"
    if ((i==N-1)); then
        cmd="$eth --mine --minerthreads=1"
    fi
    echo $cmd
    bash -c "$cmd"
done
