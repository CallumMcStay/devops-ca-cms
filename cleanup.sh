#!/bin/sh

docker rm -f chinook-db || true
docker network rm chinook-net || true
docker rmi chinook-seeder:latest || true