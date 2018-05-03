# !/bin/bash

killall node
pm2 kill
killall -QUIT geth
killall bootnode