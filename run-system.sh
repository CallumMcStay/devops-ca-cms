#!/bin/sh

set -e

docker network create chinook-net

docker run -d --net chinook-net --name chinook-db \
        -e POSTGRES_USER=callumsca \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=assignment \
    postgres:16

until docker exec chinook-db pg_isready -h localhost -U callumsca -d assignment >/dev/null 2>&1; do
  sleep 1
done

docker build --target seeder -t chinook-seeder .