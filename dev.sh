#!/usr/bin/env bash

set -e

ENV_FILE=".env"
COMPOSE_FILE=".docker/dev/docker-compose.yml"

# Detect docker compose command
if command -v docker-compose &> /dev/null; then
DOCKER_COMPOSE="docker-compose"
else
DOCKER_COMPOSE="docker compose"
fi

# Validate environment
if [ ! -f "$ENV_FILE" ]; then
echo "Environment not initialized."
echo "Run ./setup.sh first."
exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
echo "docker-compose file missing."
echo "Run ./setup.sh again."
exit 1
fi

# ------------------------
# Commands
# ------------------------

start() {
echo "Starting containers..."
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE up -d
}

stop() {
echo "Stopping containers..."
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE down
}

logs() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE logs -f
}

ps() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE ps
}

status() {
echo
echo "Container status"
echo
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE ps
echo
}

rebuild() {

echo "Cleaning build artifacts..."

rm -rf node_modules
rm -rf .next

echo "Fixing docker data permissions..."
chmod -R 777 .docker/data 2>/dev/null || true

echo "Rebuilding containers..."

$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE down
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE build --no-cache
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE up -d --force-recreate

}

ports() {

source .env

echo
echo "Services"
echo
echo "Next.js → http://localhost:$APP_PORT"

if grep -q "pgadmin:" "$COMPOSE_FILE"; then
echo "pgAdmin → http://localhost:$PGADMIN_PORT"
fi

if grep -q "redis-commander:" "$COMPOSE_FILE"; then
echo "Redis Commander → http://localhost:$REDIS_COMMANDER_PORT"
fi

echo

}

doctor() {

echo
echo "Running environment diagnostics..."
echo

if ! command -v docker &> /dev/null; then
echo "❌ Docker not installed"
exit 1
else
echo "✅ Docker installed"
fi

if ! docker info &> /dev/null; then
echo "❌ Docker not running"
exit 1
else
echo "✅ Docker running"
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
echo "❌ Docker Compose not available"
exit 1
else
echo "✅ Docker Compose available"
fi

if ! command -v node &> /dev/null; then
echo "❌ Node not installed"
exit 1
else
echo "✅ Node installed"
fi

if [ ! -f ".env" ]; then
echo "❌ .env missing"
exit 1
else
echo "✅ Environment file exists"
fi

if [ ! -f "$COMPOSE_FILE" ]; then
echo "❌ docker-compose.yml missing"
exit 1
else
echo "✅ docker-compose.yml exists"
fi

echo
echo "Environment looks good."
echo

}

version() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE exec app node -v
}

reset() {

echo "Resetting development environment..."

$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE down -v

rm -rf .docker/data

mkdir -p .docker/data/postgres
mkdir -p .docker/data/redis
mkdir -p .docker/data/pgadmin

chmod -R 777 .docker/data

echo "Environment reset complete."

}

help() {

echo
echo "Available commands"
echo
echo "start      start containers"
echo "stop       stop containers"
echo "logs       show logs"
echo "ps         show containers"
echo "status     show container status"
echo "rebuild    rebuild containers"
echo "ports      show service ports"
echo "doctor     check environment health"
echo "version    show node version"
echo "reset      reset docker environment"
echo

}

# ------------------------
# Command dispatcher
# ------------------------

case "$1" in
start) start ;;
stop) stop ;;
logs) logs ;;
ps) ps ;;
status) status ;;
rebuild) rebuild ;;
ports) ports ;;
doctor) doctor ;;
version) version ;;
reset) reset ;;
*) help ;;
esac