#!/bin/sh

docker rm -f chinook-db || true
docker network rm chinook-net || true