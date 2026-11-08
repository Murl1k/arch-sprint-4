# pymongo-api

- mongo-sharding: шардирование mongodb на два шарда
- mongo-sharding-repl: шардирование, у каждого шарда replica set из трех узлов
- sharding-repl-cache: шардирование, репликация и кеширование в redis, финальный вариант
- architecture.drawio: схемы по этапам, итоговая на последней странице

## Как запустить

переходим в директорию финального варианта

```shell
cd sharding-repl-cache
```

запускаем mongodb, redis и приложение

```shell
docker compose up -d
```

инициализируем шардирование с репликацией и заполняем mongodb данными

```shell
./scripts/mongo-init.sh
```

шаги скрипта описаны в sharding-repl-cache/README.md

## Как проверить

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

### Если вы запускаете проект на предоставленной виртуальной машине

Узнать белый ip виртуальной машины

```shell
curl --silent http://ifconfig.me
```

Откройте в браузере http://<ip виртуальной машины>:8080

### Шарды, реплики и кеш

в json будут общее количество документов в collections.helloDoc.documents_count, шарды в shards с тремя репликами в списке хостов и cache_enabled: true

команды ниже выполняютя из директории sharding-repl-cache

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

Список доступных эндпоинтов, swagger http://<ip виртуальной машины>:8080/docs
