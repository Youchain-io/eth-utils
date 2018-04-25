# !/bin/bash
# bash cluster <root> <network_id> <number_of_nodes>  <runid> <local_IP> [[params]...]
# https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster

# sets up a local ethereum network cluster of nodes
# - <number_of_nodes> is the number of nodes in cluster
# - <root> is the root directory for the cluster, the nodes are set up
#   with datadir `<root>/<network_id>/00`, `<root>/ <network_id>/01`, ...
# - new accounts are created for each node
# - they launch on port 30300, 30301, ...
# - they star rpc on port 8100, 8101, ...
# - by collecting the nodes nodeUrl, they get connected to each other
# - if enode has no IP, `<local_IP>` is substituted
# - if `<network_id>` is not 0, they will not connect to a default client,
#   resulting in a private isolated network
# - the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
# - The nodes launch in mining mode
# - the cluster can be killed with `killall geth` (FIXME: should record PIDs)
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`


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
if [ ! $ip_addr="" ]; then
  ip_addr="[::]"
fi
echo $ip_addr
shift

GETH=geth


if [ ! -f "$dir/genesis.json"  ]; then

  echo "setting up genesis"
  echo "{ \
    \"config\": { \
      \"chainId\": $network_id, \
      \"homesteadBlock\": 0, \
      \"eip155Block\": 0, \
      \"eip158Block\": 0 \
    }, \
    \"alloc\": {}, \
    \"coinbase\": \"0x0000000000000000000000000000000000000000\", \
    \"difficulty\": \"0x400\", \
    \"extraData\": \"\", \
    \"gasLimit\": \"0x47E7C4\", \
    \"nonce\": \"0x0000000000000042\", \
    \"mixhash\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \
    \"parentHash\": \"0x0000000000000000000000000000000000000000000000000000000000000000\", \
    \"timestamp\": \"0x0\" \
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

  echo "[" >> $dir/nodes
  for ((i=2;i<N+2;++i)); do
    id=`printf "%02d" $i`

    eth="$GETH --datadir $dir/data/$id --port 303$id --networkid $network_id"
    echo "initializing node"
    cmd="$eth init $dir/genesis.json"
    bash -c "$cmd" 2>&1
    echo "getting enode for instance $id ($i/$N)"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode |perl -pe "s/\[\:\:\]/$ip_addr/g" |perl -pe "s/^/\"/; s/\s*$/\"/;" |tee >> $dir/nodes
    if ((i<N+1)); then
      echo "," >> $dir/nodes
    fi

    echo "creating attach script"
    echo "$eth attach" >> $dir/attach-$id.sh
    bash -c "chmod +x $dir/attach-$id.sh"
  done
  echo "]" >> $dir/nodes
fi

for ((i=2;i<N+2;++i)); do
  id=`printf "%02d" $i`
  # echo "copy $dir/data/$id/static-nodes.json"
  mkdir -p $dir/data/$id
  # cp $dir/nodes $dir/data/$id/static-nodes.json
  echo "launching node $i/$N ---> tail-f $dir/log/$id.log"
  eth="bash ./gethup.sh $dir $id $network_id"
  cmd="$eth"
  if ((i>=N)); then
    cmd="$eth --mine --minerthreads=1"
  fi
  echo $cmd
  bash -c "$cmd"
done
