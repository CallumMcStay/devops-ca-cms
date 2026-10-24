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

docker run --rm --name chinook-seeder --net chinook-net \
    -v /Users/callummcstay/Desktop/DevOps/devops-2026-docker-assignment/Chinook.db:/app/Chinook.db:ro \
    -e SQLITE_FILE=/app/Chinook.db \
    -e DATABASE_URL=postgresql://callumsca:postgres@chinook-db:5432/assignment \
    chinook-seeder:latest

docker run -d --name chinook-gateway --net chinook-net \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /Users/callummcstay/Desktop/DevOps/devops-2026-docker-assignment/mcp_config.yaml:/mcp_config.yaml:ro \
    -v /Users/callummcstay/Desktop/DevOps/devops-2026-docker-assignment/mcp_secret.env:/run/secrets/database-url:ro \
    docker/mcp-gateway:latest \
    --transport=sse \
    --secrets=/run/secrets/database-url \
    --allow-unauthenticated \
    --servers=cockroachdb \
    --tools=execute_query \
    --config=/mcp_config.yaml

sleep 60

docker build --target agent -t chinook-agent .

docker run --rm --name chinook-agent --net chinook-net \
    -v /Users/callummcstay/Desktop/DevOps/devops-2026-docker-assignment/secret.ollama-api-key:/run/secrets/openai-api-key:ro \
    -e MCP_SERVER_URL=http://chinook-gateway:8811/sse \
    -e DATABASE_DIALECT=PostgreSQL \
    -e QUESTION="What are the top 3 albums by sales?" \
    -e OPENAI_API_BASE_URL=https://ollama.com/v1 \
    -e OPENAI_MODEL_NAME=gpt-oss:20b \
    chinook-agent:latest