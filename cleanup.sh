#!/bin/sh

docker ps -a --filter "label=project=chinook" -q | xargs -r docker rm -f || true
docker volume ls --filter "label=project=chinook" -q | xargs -r docker volume rm || true
docker network ls --filter "label=project=chinook" -q | xargs -r docker network rm || true
docker image ls --filter "label=project=chinook" -q | xargs -r docker rmi || true