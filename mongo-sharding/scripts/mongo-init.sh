#!/bin/bash

###
# Инициализируем бд
###

wait_mongo() {
  until docker compose exec -T "$1" mongosh --port "$2" --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; do
    sleep 1
  done
}

wait_rs() {
  until [ "$(docker compose exec -T "$1" mongosh --port "$2" --quiet --eval "rs.status().members.filter(m => m.stateStr == 'PRIMARY').length == 1 && rs.status().members.filter(m => m.stateStr == 'SECONDARY').length == $3" 2> /dev/null)" = "true" ]; do
    sleep 1
  done
}

wait_mongo configSrv 27017
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({_id: "config_server", configsvr: true, members: [{_id: 0, host: "configSrv:27017"}]})
EOF

wait_mongo shard1 27018
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({_id: "shard1", members: [{_id: 0, host: "shard1:27018"}]})
EOF

wait_mongo shard2 27019
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({_id: "shard2", members: [{_id: 0, host: "shard2:27019"}]})
EOF

wait_rs configSrv 27017 0
wait_rs shard1 27018 0
wait_rs shard2 27019 0
wait_mongo mongos_router 27020

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1:27018")
sh.addShard("shard2/shard2:27019")
sh.enableSharding("somedb")
sh.shardCollection("somedb.helloDoc", {"name": "hashed"})
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
db.helloDoc.countDocuments()
EOF
