BOS Hyperion History API
---------------

BOS Hyperion History API realizes the original V1 API for EOSIO. So it can be used by wallets, exchanges, explorers directly.

Here are the steps how to setup a Hyperion BOS node, this manual was tested in Ubuntu 18.04(64bits):

## Setup Environment

### Start BOS node

Hyperion depends on `state_history_plugin`, it needs to start the `nodoes` with `genesis.json` and the configures in the `config.ini` file:

```
state-history-dir = "state-history"
trace-history = true
chain-state-history = true
state-history-endpoint = 0.0.0.0:8080
plugin = eosio::state_history_plugin
```

For quickly start the BOS `nodeos`, you can use the docker-compose file: 
```
version: "3"

services:
  bosmainnode:
    image: boscore/bos:latest
    command: /opt/eosio/bin/nodeosd.sh --data-dir /opt/eosio/bin/data-dir --max-irreversible-block-age=5000000 --max-transaction-time=100000 --wasm-runtime wabt --genesis-json=/opt/eosio/bin/data-dir/genesis.json  --disable-replay-opts
    #--snapshot /opt/eosio/bin/data-dir/snapshot-2019-10-19-15-bos.bin
    hostname: bosmainnode
    ports:
      - 180:80
      - 8080:8080
      - 543:443
    environment:
      - NODEOSPORT=80
      - WALLETPORT=8888
    volumes:
      - /data/bos/mainnet:/opt/eosio/bin/data-dir
```

_Note: 
  * BOS Mainnet [genesis.json](https://raw.githubusercontent.com/boscore/bosres/master/genesis.json)
  * BOS Testnet [genesis.json](https://raw.githubusercontent.com/boscore/bos-testnet/master/genesis.json)


### Install NodeJS 

```bash
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install PM2

```bash
sudo npm install pm2@latest -g
sudo pm2 startup
```

### Install ElasticSearch

Ideally, ElasticSearch should run in a separated machine and can use all the resources of the machine.

In this manual, ElasticSearch will run in same machine with Hyperion-API, but something need to be done for ElasticSearch.

* Increase file limits to unlimit
* Disable the `SWAP` partition to get a better performanc for ElasticSearch 

The detail system settings for ElasticSearch can be find [here](https://www.elastic.co/guide/en/elasticsearch/reference/master/setting-system-settings.html)

Follow instructions on https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html (Ubuntu/Debian)

Here is the cmdline used:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y
```

then, edit `/etc/elasticsearch/elasticsearch.yml`

```
cluster.name: boshyperion
bootstrap.memory_lock: true
```

_Note: You can repleace `boshyperion` with your favorite one. 


Edit `/etc/elasticsearch/jvm.options`
```
# Set your heap size, avoid allocating more than 31GB, even if you have enought RAM.
# Test on your specific machine by changing -Xmx32g in the following command:
# java -Xmx32g -XX:+UseCompressedOops -XX:+PrintFlagsFinal Oops | grep Oops
-Xms8g
-Xmx8g
```

_Note: The speical number depends on you machine memory capacity. It should be small than the total system memory, 40% of your real memory recommanded as this machine not only for ElasticSearch.


As the systemd service file contains the limits that are applied by default. 
Run `sudo systemctl edit elasticsearch` and add the following lines: 
```
[Service]
LimitMEMLOCK=infinity
```

Start elasticsearch and check the logs (verify if the memory lock was successful)

```bash
sudo service elasticsearch start
sudo less /var/log/elasticsearch/boshyperion.log
sudo systemctl enable elasticsearch
```

Test the REST API `curl http://localhost:9200`

```
{
  "name" : "ip-172-31-5-121",
  "cluster_name" : "hyperion",
  "cluster_uuid" : "....",
  "version" : {
    "number" : "7.1.0",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "606a173",
    "build_date" : "2019-05-16T00:43:15.323135Z",
    "build_snapshot" : false,
    "lucene_version" : "8.0.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

If you want reset ElasticSearch instance for Hyperion-API, you can call:
```bash
curl -XDELETE localhost:9200/*abi*
curl -XDELETE localhost:9200/*bos*   # bos is the chain name
```

Change ElasticSearch data and log storing path:

1. Stop ElasticSearch
```bash
sudo service elasticsearch stop
```

2. Update configure file
```bash
sudo vim /etc/elasticsearch/elasticsearch.yml
# change the configures
path.data: /data/lib/elasticsearch
path.logs: /data/log/elasticsearch

sudo vim /etc/elasticsearch/jvm.options
# change the Path into you new path, default is `/var/log/elasticsearch` and `/var/lib/elasticsearch`
```

3. Create directories and copy files
```bash
mkdir -p /data/lib/ /data/log/

sudo mv /var/lib/elasticsearch /data/lib
sudo mv /var/log/elasticsearch /data/log
```

4. Start ElasticSearch
```bash
sudo service elasticsearch start
```


### Install Kibana 

```bash
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.4.0-amd64.deb
sudo apt install ./kibana-7.4.0-amd64.deb
sudo /lib/systemd/systemd-sysv-install enable kibana
sudo systemctl enable kibana
sudo service kibana start
```

Open and test Kibana on `curl http://localhost:5601 -v`.


### Install RabbitMQ

Reference this link to install [RabbitMQ](https://www.rabbitmq.com/install-debian.html#apt-bintray-quick-start)

```bash
## Install prerequisites
sudo apt-get install curl gnupg -y
## Install RabbitMQ signing key
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -
## Add Bintray repositories that provision latest RabbitMQ and Erlang 21.x releases
sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
## Installs the latest Erlang 21.x release.
## Change component to "erlang" to install the latest version (22.x or later).
## "bionic" as distribution name should work for any later Ubuntu or Debian release.
## See the release to distribution mapping table in RabbitMQ doc guides to learn more.
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang-21.x
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF
## Update package indices
sudo apt-get update -y
## Install rabbitmq-server and its dependencies
sudo apt-get install rabbitmq-server -y --fix-missing


# Configure for Hyperion-APi
my_user=ubuntu      # change by yourself
my_password=ubuntu123456  # change by yourself

sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl add_vhost /hyperion
sudo rabbitmqctl add_user ${my_user} ${my_password}
sudo rabbitmqctl set_user_tags ${my_user} administrator
sudo rabbitmqctl set_permissions -p /hyperion ${my_user} ".*" ".*" ".*"
```

Check access to the WebUI `curl http://localhost:15672 -v`. 

Operations to rabbitmq: 

```bash
sudo service rabbitmq-server status
sudo service rabbitmq-server start
```

Change Rabbitmq data and log store path:

1. Stop rabbitmq
```bash
sudo service rabbitmq-server stop
````

2. Add conf file:
```bash
sudo vim /etc/rabbitmq/rabbitmq-env.conf

# input the file content
RABBITMQ_MNESIA_BASE=/data/lib/rabbitmq/mnesia
RABBITMQ_LOG_BASE=/data/lib/rabbitmq/log
```

3. Create directory and copy old data
```bash
mkdir -p /data/lib/rabbitmq
sudo chown rabbitmq:rabbitmq /data/lib/rabbitmq/
sudo mv -v /var/lib/rabbitmq/* /data/lib/rabbitmq/
``` 

4. Start Rabbitmq and check status
```bash
sudo service rabbitmq-server start
sudo service rabbitmq-server status
```


### Install Redis

```bash
sudo apt install redis-server -y
```
If you need adjust the IP or PORT, you can edit `/etc/redis/redis.conf`. 

Redis service cmdlines:

```bash
sudo systemctl restart redis.service
```

### Install Nginx

```
sudo apt install nginx -y
```

For nginx config file, you can modify base on `exmaple-nginx.conf`. 
After the config file is ready, let nginx reload the configure. 

```
# reload configure
sudo service nginx reload
# test configure
sudo service nginx -t
```

### Install Hyperion Indexer

```bash
sudo chown -R $USER:$(id -gn $USER) ~/.config

git clone https://github.com/boscore/Hyperion-History-API.git
cd Hyperion-History-API
npm install
cp example-ecosystem.config.js ecosystem.config.js
```

At the begining, Hyperion-API need to load templates first by starting the Hyperion Indexer in preview mode `PREVIEW: 'true'` in ecosystem.config.js. 
And in the next time, `PREVIEW: 'false'` should be used.

*WARNING: all the service should be running inlucde nodeos with `state_history_plugin`, before Hyperion-API runing.*

#### PREVIEW set `true` for first launch

Edit `ecosystem.config.js`, change `PREVIEW: 'true'` and save. And start Hyperion-API for the first time.

`ecosystem.config.js` :
```
REWRITE: "true",
```

```bash
cd Hyperion-History-API
sudo pm2 start --update-env
# check logs
sudo pm2 logs
```

#### PREVIEW set `false` for next launch

Edit `ecosystem.config.js`, change `PREVIEW: 'false'` and save.

`ecosystem.config.js` :
```
REWRITE: "false",
```

```bash
sudo pm2 stop all
sudo pm2 start --update-env
# check logs
sudo pm2 logs

```

#### WARNING: when you modify the `env` in `ecosystem.config.js`, you had better call :
```
sudo pm2 restart ecosystem.config.js --update-env
```


## Others

### Cmdlines to query ElasticSearch

[cmdline](./docs/cmdline.sh)


### Setup Indices and Aliases

Indices and aliases are created automatically using the `CREATE_INDICES` option (set it to your version suffix e.g, v1, v2, v3)
If you want to create them manually, use the commands bellow on the kibana dev console
```
PUT mainnet-action-v1-000001
PUT mainnet-abi-v1-000001
PUT mainnet-block-v1-000001

POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "mainnet-abi-v1-000001",
        "alias": "mainnet-abi"
      }
    },
    {
      "add": {
        "index": "mainnet-action-v1-000001",
        "alias": "mainnet-action"
      }
    },
    {
      "add": {
        "index": "mainnet-block-v1-000001",
        "alias": "mainnet-block"
      }
    }
  ]
}
```

Before indexing actions into elasticsearch its required to do a ABI scan pass

Start with
```
ABI_CACHE_MODE: true,
FETCH_BLOCK: 'false',
FETCH_TRACES: 'false',
INDEX_DELTAS: 'false',
INDEX_ALL_DELTAS: 'false',
```

Tune your configs to your specific hardware using the following settings:
```
BATCH_SIZE
READERS
DESERIALIZERS
DS_MULT
ES_INDEXERS_PER_QUEUE
ES_ACT_QUEUES
READ_PREFETCH
BLOCK_PREFETCH
INDEX_PREFETCH
```

