# query transaction info from ElasticSearch by txid
curl -X GET "localhost:9200/bos-action-v1-000001/_search?pretty" -H 'Content-Type: application/json' -d'
{
    "query": {
        "match" : {
            "trx_id" : "c4a2ef620464e3b199996a6b50a35771be39b50f2d6f6a5781ff0bbf850917a2"
        }
    }
}
'

# query block infomation from ElasticSearch by block number
curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "range":{
            "block_num":{
                "gte":1000
            }
        }   
    }
}
'
# query actions infomation from ElasticSearch by account
curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "match": { "act.account": "oracletest23"}
    }
}
'
curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "match": { "act.account": "eosio"}
    }
}
'

# query action infomation from ElasticSearch by filers
curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "range":{
            "@timestamp":{
                "gte": "2019-08-26T15:43:11.500"
            }
        }
    }
}
'

curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "filter":{
            "range": {
                "@timestamp":{
                    "gte": "2019-08-26T15:43:11.500"
                }
            }
        }
    }
}'
 
curl -X GET 'localhost:9200/bos-action-v1-000001/_search?pretty' -H "Content-Type:application/json" -d'
{
    "query":{
        "range":{
            "block_num":{
                "gte":43878138
            }
        }   
    }
}
'


curl -X GET "localhost:9200/bos-action-v1-000001/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": { 
    "bool": { 
      "must": [
        { "match": { "act.account": "oracletest23"}}
      ],
      "filter": [ 
        { "range": { 
            "@timestamp":{
                "gte": "2018-09-02T15:43:11.500"
            }
        }}
      ]
    }
  }
}
'
