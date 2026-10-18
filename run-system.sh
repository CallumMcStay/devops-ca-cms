#!/bin/sh

set -e

docker network create chinook-net

docker run -d --net chinook-net --name chinook-db \
        -e POSTGRES_USER=callumsca \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=assignment \
    postgres:16