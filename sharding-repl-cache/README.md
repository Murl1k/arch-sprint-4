# sharding-repl-cache

## Как запустить

запускаем mongodb, redis и приложение

```shell
docker compose up -d
```

инициализируем шардирование с репликацией и заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

шаги скрипта:

1. дожидается запуска configSrv и инициализирует replica set config_server
2. дожидается запуска узлов shard1-1, shard1-2, shard1-3 и инициализирует replica set shard1 из трех узлов
3. дожидается запуска узлов shard2-1, shard2-2, shard2-3 и инициализирует replica set shard2 из трех узлов
4. дожидается, пока в каждом шарде будут один primary и два secondary
5. через mongos_router добавляет шарды shard1 и shard2 со всеми узлами
6. включает шардирование коллекции somedb.helloDoc по хешу поля name
7. записывает 1000 документов и выводит их количество

кеш включается переменной REDIS_URL у pymongo_api, отдельно настраивать redis не нужно

## Как проверить

откройте в браузере http://localhost:8080, в json будут общее количество документов в collections.helloDoc.documents_count, шарды в shards с тремя репликами в списке хостов и cache_enabled: true

количество документов в shard1

```shell
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

количество документов в shard2

```shell
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

реплики shard1 и их состояние

```shell
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.status().members.map(m => m.name + " " + m.stateStr)
EOF
```

реплики shard2 и их состояние

```shell
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.status().members.map(m => m.name + " " + m.stateStr)
EOF
```

время запросов к /helloDoc/users: первый запрос идет в mongodb и занимает около секунды, повторные в течение минуты берутся из redis быстрее 100 мс

```shell
for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{time_total}\n" http://localhost:8080/helloDoc/users; done
```

## Доступные эндпоинты

список доступных эндпоинтов, swagger http://localhost:8080/docs
