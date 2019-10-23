# Hyperion History API
---------------

Scalable Full History API Solution for EOSIO based blockchains.

We build this history tool based on [EOS Rio's](https://eosrio.io/) solution and add EOSIO's `history_plugin` features,
which means that it is compatible with the `v1` API provided by `history_plugin`.

With this tool, developers don't have to run a full history node with `history_plugin`, which would cost much expenses.

### Introducing an storage-optimized action format for EOSIO

The original *history_plugin* bundled with eosio, that provided the v1 api, stored inline action traces nested inside their root actions. This led to an excessive amount of data being stored and also transferred whenever a user requested the action history for a given account. Also inline actions are used as a "event" mechanism to notify parties on a transaction. Based on those Hyperion implements some changes

1. actions are stored in a flattened format
2. a parent field is added to the inline actions to point to the parent global sequence
3. if the inline action data is identical to the parent it is considered a notification and thus removed from the database
4. no blocks or transaction data is stored, all information can be reconstructed from actions

With those changes the API format focus on delivering faster search times, lower bandwidth overhead and easier usability for UI/UX developers. 

#### Action Data Structure

 - `@timestamp` - block time
 - `global_sequence` - unique action global_sequence, used as index id
 - `parent` - points to the parent action (in the case of an inline action) or equal to 0 if root level
 - `block_num` - block number where the action was processed
 - `trx_id` - transaction id
 - `producer` - block producer
 - `act`
    - `account` - contract account
    - `name` - contract method name
    - `authorization` - array of signers
        - `actor` - signing actor
        - `permission` - signing permission
    - `data` - action data input object
 - `account_ram_deltas` - array of ram deltas and payers
    - `account`
    - `delta`
 - `notified` - array of accounts that were notified (via inline action events)

## Dependencies

This setup has only been tested with Ubuntu 18.04, but should work with other OS versions too

 - [Elasticsearch 7.3.2](https://www.elastic.co/downloads/elasticsearch)
 - [RabbitMQ](https://www.rabbitmq.com/install-debian.html)
 - [Redis](https://redis.io/topics/quickstart)
 - [Node.js v12](https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions)
 - [PM2](https://pm2.io/doc/en/runtime/quick-start)
  
  > The indexer requires redis, pm2 and node.js to be on the same machine. Other dependencies might be installed on other machines, preferably over a very high speed and low latency network. Indexing speed will vary greatly depending on this configuration.
  
## Setup Instructions

#### 1. Clone & Install packages

Follow [INSTALL.md](./INSTALL.md)

#### 2. Edit configs
`nano ecosystem.config.js`

Reference
```
AMQP_HOST: '127.0.0.1:5672'            // RabbitMQ host:port
AMQP_USER: '',                         // RabbitMQ user
AMQP_PASS: '',                         // RabbitMQ password
ES_HOST: '127.0.0.1:9200',             // elasticsearch http endpoint
NODEOS_HTTP: 'http://127.0.0.1:8888',  // chain api endpoint
NODEOS_WS: 'ws://127.0.0.1:8080',      // state history endpoint
LIVE_READER: 'true',                   // enable continuous reading after reaching the head block
FETCH_DELTAS: 'false',                 // read table deltas
CHAIN: 'eos',                          // chain prefix for indexing
CREATE_INDICES: 'v1',                  // index suffix to be created, set to false to use existing aliases
START_ON: 0,                           // start indexing on block (0=disable)
STOP_ON: 0,                            // stop indexing on block  (0=disable)
REWRITE: 'false',                      // force rewrite the target replay range
BATCH_SIZE: 2000,                      // parallel reader batch size in blocks
LIVE_ONLY: 'false',                    // only reads realtime data serially
FETCH_BLOCK: 'true',
FETCH_TRACES: 'true',
PREVIEW: 'false',                      // preview mode - prints worker map and exit
DISABLE_READING: 'false',              // completely disable block reading, for lagged queue processing
READERS: 3,                            // parallel state history readers
DESERIALIZERS: 4,                      // deserialization queues
DS_MULT: 4,                            // deserialization threads per queue
ES_INDEXERS_PER_QUEUE: 4,              // elastic indexers per queue
ES_ACT_QUEUES: 2,                      // multiplier for action indexing queues
READ_PREFETCH: 50,                     // Stage 1 prefecth
BLOCK_PREFETCH: 5,                     // Stage 2 prefecth
INDEX_PREFETCH: 500,                   // Stage 3 prefetch
ENABLE_INDEXING: 'true',               // enable elasticsearch indexing
INDEX_DELTAS: 'true',                  // index common table deltas (see delta on definitions/mappings)
INDEX_ALL_DELTAS: 'false',             // index all table deltas (WARNING)
ABI_CACHE_MODE: 'false'                // cache historical ABIs to redis
```

#### 3. Starting

```
# start all
pm2 start --update-env

# Only start Indexer
pm2 start --only Indexer --update-env
# Onlye start API
pm2 start --only API --update-env
```

#### 4. Stopping

Stop reading and wait for queues to flush
```
# Indexer
pm2 trigger Indexer stop
# API
pm2 trigger API stop
```

Force stop
```
pm2 stop all
pm2 stop Indexer
pm2 stop API 
```

#### 5. Logging

```
pms logs
pm2 logs API
pm2 logs Indexer
```
 
## API Reference

Documentation is automatically generated by Swagger/OpenAPI.

Example: [OpenAPI Docs](https://eos.hyperion.eosrio.io/v2/docs)

