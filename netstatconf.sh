# !/bin/bash
# bash intelligence <destination_app_json_path> <number_of_clusters> <name_prefix> <ws_server> <ws_secret> <ip_addr>

# sets up a eth-net-intelligence app.json for a local ethereum network cluster of nodes
# - <number_of_clusters> is the number of clusters
# - <name_prefix> is a prefix for the node names as will appear in the listing
# - <ws_server> is the eth-netstats server
# - <ws_secret> is the eth-netstats secret
# - <ip_addr> is the network ip
#

N=$1
shift
name_prefix=$1
shift
ws_server=$1
shift
ws_secret=$1
shift
ip_addr=$1
shift

echo "["

for ((i=0;i<N;++i)); do
    id=`printf "%02d" $((i+1))`
    port=`printf "%02d" $((i+2))`

    single_template="{ \n\
    \"name\": \"$name_prefix-$id\", \n\
    \"cwd\": \".\", \n\
	\"script\": \"app.js\", \n\
	\"log_date_format\": \"YYYY-MM-DD HH:mm Z\", \n\
	\"merge_logs\": false, \n\
	\"watch\": false, \n\
	\"exec_interpreter\": \"node\", \n\
	\"exec_mode\": \"fork_mode\", \n\
	\"env\": { \n\
		\"NODE_ENV\": \"production\", \n\
		\"RPC_HOST\": \"$ip_addr\", \n\
		\"RPC_PORT\": \"81$port\", \n\
		\"LISTENING_PORT\": \"303$port\", \n\
		\"INSTANCE_NAME\": \"$name_prefix-$id\", \n\
		\"WS_SERVER\": \"$ws_server\", \n\
		\"WS_SECRET\": \"$ws_secret\", \n\
	} \n\
}"

    endline=""
    if ((i<N-1)); then
        endline=", "
    fi
    echo "$single_template$endline"
done

echo "]"
