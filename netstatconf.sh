#!/bin/bash

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

if [ -z $N ] || [ -z $name_prefix ] || [ -z $ws_server ] || [ -z $ws_secret ] || [ -z $ip_addr ]; then
    echo " USAGE:"
    echo "   ./netstatconf.sh <N> <name_prefix> <ws_server> <ws_secret> <ip_addr>"
    echo
    echo " ARGUMENTS:"
    echo "     <N>                 number of nodes"
    echo "     <name_prefix>       prefix to construct the node name"
    echo "     <ws_server>         the server URL"
    echo "     <ws_secret>         the server secret password"
    echo "     <ip_addr>           local IP address"
    echo
    exit 1
fi


echo -n "["
for ((i=0;i<N;++i)); do
    id=`printf "%02d" $((i+1))`
    port=`printf "%02d" $((i+2))`

    echo -e "{ \n\
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
    }"

    endline="}"
    if ((i<N-1)); then
        endline="$endline, "
    fi
    echo -n "$endline"
done
echo "]"
