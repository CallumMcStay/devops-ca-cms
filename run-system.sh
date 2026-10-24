#!/bin/sh

#Safety to stop the script if any command fails
set -e

#Create a docker volume to allow me to remove it in cleanup.sh
docker volume create chinook-volume

#Create a Docker network for the containers to communicate
docker network create chinook-net

#Start the PostgreSQL database container, using -d to run it in detached mode
docker run -d --net chinook-net --name chinook-db \
        -v chinook-volume:/var/lib/postgresql/data \
        -e POSTGRES_USER=callumsca \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=assignment \
    postgres:16

# Wait for the database to be ready before proceeding
until docker exec chinook-db pg_isready -h localhost -U callumsca -d assignment >/dev/null 2>&1; do
  sleep 1
done

# Build the seeder image
docker build --target seeder -t chinook-seeder .

# Run the seeder container to populate the database
docker run --rm --name chinook-seeder --net chinook-net \
    -v "$PWD/Chinook.db:/app/Chinook.db:ro" \
    -e SQLITE_FILE=/app/Chinook.db \
    -e DATABASE_URL=postgresql://callumsca:postgres@chinook-db:5432/assignment \
    chinook-seeder:latest

#Lets the agent talk to the DB through the gateway using MCP.
docker run -d --name chinook-gateway --net chinook-net \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD/mcp_config.yaml:/mcp_config.yaml:ro" \
    -v "$PWD/mcp_secret.env:/run/secrets/database-url:ro" \
    docker/mcp-gateway:latest \
    --transport=sse \
    --secrets=/run/secrets/database-url \
    --allow-unauthenticated \
    --servers=cockroachdb \
    --tools=execute_query \
    --config=/mcp_config.yaml

#Waits 60 seconds to allow the gateway to start up and be ready
sleep 60

#Build the agent image
docker build --target agent -t chinook-agent .

#Run the agent container with the question its asking the Database. No -d so the info is printed to the console.
docker run --rm --name chinook-agent --net chinook-net \
    -v "$PWD/secret.ollama-api-key:/run/secrets/openai-api-key:ro" \
    -e MCP_SERVER_URL=http://chinook-gateway:8811/sse \
    -e DATABASE_DIALECT=PostgreSQL \
    -e QUESTION="What are the top 3 albums by sales?" \
    -e OPENAI_API_BASE_URL=https://ollama.com/v1 \
    -e OPENAI_MODEL_NAME=gpt-oss:20b \
    chinook-agent:latest