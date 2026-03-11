#!/usr/bin/env bash

set -e

if command -v docker-compose &> /dev/null; then
DOCKER_COMPOSE="docker-compose"
else
DOCKER_COMPOSE="docker compose"
fi

ENV_FILE=".env"
COMPOSE_FILE=".docker/dev/docker-compose.yml"

if [ ! -f "$ENV_FILE" ]; then
echo "Environment not initialized."
echo "Run ./setup.sh first."
exit 1
fi

start() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE up -d
}

stop() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE down
}

logs() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE logs -f
}

ps() {
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE ps
}

rebuild() {

echo "Cleaning build artifacts..."

rm -rf node_modules
rm -rf .next

echo "Fixing docker data permissions..."
chmod -R 777 .docker/data 2>/dev/null || true

$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE down -v
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE build --no-cache
$DOCKER_COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE up -d --force-recreate

}

ports() {

source .env

echo
echo "Services"
echo
echo "Next.js → http://localhost:$APP_PORT"
echo "pgAdmin → http://localhost:$PGADMIN_PORT"
echo "Redis Commander → http://localhost:$REDIS_COMMANDER_PORT"
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
echo "rebuild    rebuild containers"
echo "ports      show service ports"
echo "doctor     check environment health"
echo "version    show node version"
echo "reset      reset docker environment"
echo

}

case "$1" in
start) start ;;
stop) stop ;;
logs) logs ;;
ps) ps ;;
rebuild) rebuild ;;
ports) ports ;;
doctor) doctor ;;
version) version ;;
reset) reset ;;
*) help ;;
esac