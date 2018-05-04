#!/bin/bash

root=$1
shift
network_id=$1
shift

if [ -z $root ] || [ -z $network_id ]; then
    echo
    echo "  ##################################################"
    echo "  # WARN - You're going to erase all your files... #"
    echo "  ##################################################"
    echo
    echo " USAGE:"
    echo "   ./yc-clean.sh <root> <network_id>"
    echo
    echo " ARGUMENTS:"
    echo "     <root>              root path of your nodes' data"
    echo "     <network_id>        network id"
    echo
    exit 1
fi

./yc-stop.sh
rm -rf $root/$network_id/*
