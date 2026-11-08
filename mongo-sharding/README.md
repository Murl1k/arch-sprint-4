# mongo-sharding

## Как запустить

запускаем mongodb и приложение

```shell
docker compose up -d
```

инициализируем шардирование и заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

шаги скрипта:

1. дожидается запуска configSrv и инициализирует replica set config_server
2. дожидается запуска shard1 и shard2 и инициализирует replica set каждого шарда
3. дожидается выбора primary в каждом replica set
4. через mongos_router добавляет шарды shard1 и shard2
5. включает шардирование коллекции somedb.helloDoc по хешу поля name
6. записывает 1000 документов и выводит их колличество

## Как проверить

откройте в браузере http://localhost:8080, в json будут общее количество документов в collections.helloDoc.documents_count и список шардов в shards

количество документов в shard1

```shell
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

количество документов в shard2

```shell
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

## Доступные эндпоинты

список доступных эндпоинтов, swagger http://localhost:8080/docs
