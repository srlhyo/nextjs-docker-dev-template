#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE=".env"
COMPOSE_FILE=".docker/dev/docker-compose.yml"

if command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE="docker-compose"
else
  DOCKER_COMPOSE="docker compose"
fi

dc() {
$DOCKER_COMPOSE --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

require_env() {
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env file"
  exit 1
fi
}

start() {
echo "Starting containers..."
dc up -d
}

stop() {
echo "Stopping containers..."
dc down
}

logs() {
dc logs -f
}

status() {
dc ps
}

wait_postgres() {

if ! dc ps | grep -q postgres; then
  return
fi

echo "Waiting for PostgreSQL..."

until dc exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do
  sleep 2
done

echo "PostgreSQL ready"
}

rebuild() {

echo "Rebuilding environment..."

dc down
dc build --no-cache
dc up -d

wait_postgres

echo "Running Prisma setup..."

dc exec -T app npx prisma generate || true
dc exec -T app npx prisma migrate deploy || true

echo
echo "Environment ready"
echo
}

ports() {

set -a
source .env
set +a

echo
echo "Services"
echo

echo "Next.js → http://localhost:$APP_PORT"
echo "Prisma Studio → http://localhost:$PRISMA_STUDIO_PORT"

if grep -q pgadmin "$COMPOSE_FILE"; then
echo "pgAdmin → http://localhost:$PGADMIN_PORT"
fi

if grep -q redis-commander "$COMPOSE_FILE"; then
echo "Redis Commander → http://localhost:$REDIS_COMMANDER_PORT"
fi

echo
}

doctor() {

echo
echo "Environment diagnostics"
echo

for cmd in docker; do
if command -v $cmd >/dev/null; then
echo "✔ $cmd installed"
else
echo "✖ $cmd missing"
exit 1
fi
done

if docker info >/dev/null 2>&1; then
echo "✔ Docker running"
else
echo "✖ Docker not running"
exit 1
fi

if docker compose version >/dev/null 2>&1 || docker-compose version >/dev/null 2>&1; then
echo "✔ Docker Compose available"
else
echo "✖ Docker Compose missing"
exit 1
fi

echo
}

reset() {

echo "Resetting docker environment..."

dc down -v
rm -rf .docker/data

mkdir -p .docker/data/postgres
mkdir -p .docker/data/redis
mkdir -p .docker/data/pgadmin

chmod -R 777 .docker/data

echo "Reset complete"
}

npm_install() {
dc exec app npm install
}

prisma_generate() {
dc exec app npx prisma generate
}

prisma_migrate() {
dc exec app npx prisma migrate dev
}

prisma_push() {
dc exec app npx prisma db push
}

prisma_reset() {
dc exec app npx prisma migrate reset --force
}

studio() {
dc up -d prisma-studio
}

case "${1:-}" in

start) start ;;
stop) stop ;;
logs) logs ;;
status) status ;;
rebuild) rebuild ;;
ports) ports ;;
doctor) doctor ;;
reset) reset ;;
install) npm_install ;;
generate) prisma_generate ;;
migrate) prisma_migrate ;;
push) prisma_push ;;
db-reset) prisma_reset ;;
studio) studio ;;

*)

echo
echo "Commands:"
echo
echo "start      Start containers"
echo "stop       Stop containers"
echo "logs       Show logs"
echo "status     Container status"
echo "rebuild    Rebuild environment"
echo "ports      Show service ports"
echo "doctor     Environment diagnostics"
echo "reset      Reset docker data"
echo
echo "Prisma:"
echo "generate   Generate client"
echo "migrate    Run migrations"
echo "push       Push schema"
echo "db-reset   Reset database"
echo "studio     Start Prisma Studio"
echo

;;

esac