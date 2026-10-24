#!/bin/sh

docker ps -a --filter "label=project=chinook" -q | xargs -r docker rm -f || true
docker volume rm chinook-volume || true
docker network rm chinook-net || true
docker rmi chinook-seeder:latest || true
docker rmi chinook-agent:latest || true