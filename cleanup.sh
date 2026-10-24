#!/bin/sh

docker rm -f chinook-agent || true
docker rm -f chinook-seeder || true
docker rm -f chinook-gateway || true
docker rm -f chinook-db || true
docker volume rm chinook-volume || true
docker network rm chinook-net || true
docker rmi chinook-seeder:latest || true
docker rmi chinook-agent:latest || true