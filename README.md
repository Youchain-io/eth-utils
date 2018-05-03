## eth-utils

ethereum utilities, dev tools, scripts, etc

* `gethup.sh`: primitive wrapper to [geth](https://github.com/ethereum/go-ethereum)
* `gethcluster.sh`: launch local clusters non-interactively (https://github.com/ethereum/go-ethereum/wiki/Setting-up-private-network-or-local-cluster)
* `netstatconf.sh`: auto-generate the json config of your local cluster for netstat (https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster)

##  Usage

### Launch a cluster and monitor
```
./yc-start.sh <root_path> <network_id> <nodes_nbr>
```

```
open http://localhost:30300
```

### Stop all clusters and monitors
```
./yc-stop.sh
```

### Clean everything
```
./yc-clean.sh
```
