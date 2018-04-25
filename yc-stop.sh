# !/bin/bash

killall -QUIT geth
rm -rf /Users/guytou/TBOX/PERSO/youchain/ethereum/network/private/1906/*
killall bootnode
ps |grep bootnode
