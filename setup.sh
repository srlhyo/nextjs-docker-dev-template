#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ENV_FILE=".env"
DOCKER_DIR=".docker"
COMPOSE_FILE=".docker/dev/docker-compose.yml"

print_banner() {
  echo
  echo "🚀 Next.js Docker Project Setup"
  echo "Project: $(basename "$PWD")"
  echo
}

detect_docker_compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
  else
    DOCKER_COMPOSE="docker compose"
  fi
}

check_dependencies() {

  for cmd in docker node npx openssl; do
    if ! command -v $cmd >/dev/null 2>&1; then
      echo -e "${RED}$cmd is not installed.${NC}"
      exit 1
    fi
  done

  if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Docker daemon is not running.${NC}"
    exit 1
  fi
}

ensure_empty_project() {
  if [ -f package.json ]; then
    echo -e "${RED}A project already exists here.${NC}"
    exit 1
  fi
}

ask_services() {

  echo
  echo "Optional services"
  echo

  read -rp "Include PostgreSQL? (Y/n): " USE_POSTGRES
  read -rp "Include Redis? (Y/n): " USE_REDIS
  read -rp "Include pgAdmin? (Y/n): " USE_PGADMIN
  read -rp "Include Redis Commander? (Y/n): " USE_REDIS_COMMANDER

  USE_POSTGRES=${USE_POSTGRES:-Y}
  USE_REDIS=${USE_REDIS:-Y}
  USE_PGADMIN=${USE_PGADMIN:-Y}
  USE_REDIS_COMMANDER=${USE_REDIS_COMMANDER:-Y}

  if [[ ! "$USE_POSTGRES" =~ ^[Yy]$ ]]; then
    USE_PGADMIN="n"
  fi

  if [[ ! "$USE_REDIS" =~ ^[Yy]$ ]]; then
    USE_REDIS_COMMANDER="n"
  fi
}

find_port() {
  local port=$1
  while ss -tuln | grep -q ":$port "; do
    port=$((port+1))
  done
  echo "$port"
}

create_nextjs_project() {

  echo -e "${YELLOW}Creating Next.js project (Docker isolated)...${NC}"

  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/app -w /app node:22 \
    bash -c "
      mkdir temp-app &&
      cd temp-app &&
      npx create-next-app@latest . \
        --typescript \
        --tailwind \
        --eslint \
        --app \
        --src-dir \
        --import-alias '@/*' \
        --use-npm \
        --yes
    "

  shopt -s dotglob
  mv temp-app/* .
  rm -rf temp-app
  shopt -u dotglob

  rm -rf .git node_modules .next package-lock.json
}

install_prisma() {

  echo -e "${YELLOW}Installing Prisma...${NC}"

  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/app -w /app node:22 \
    bash -c "
      npm install prisma dotenv --save-dev &&
      npm install @prisma/client &&
      npx prisma init
    "

}

create_structure() {

  mkdir -p $DOCKER_DIR/dev
  mkdir -p $DOCKER_DIR/data/postgres
  mkdir -p $DOCKER_DIR/data/redis
  mkdir -p $DOCKER_DIR/data/pgadmin

  chmod -R 777 $DOCKER_DIR/data
}

create_dockerfile() {

cat > .docker/dev/Dockerfile <<'EOF'
FROM node:22-slim

RUN apt-get update -y \
 && apt-get install -y openssl xdg-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

RUN npm config set fund false \
 && npm config set audit false

COPY . .

EXPOSE 3000

CMD ["npm","run","dev"]
EOF

}

create_docker_compose() {

cat > "$COMPOSE_FILE" <<'EOF'
services:

  app:
    build:
      context: ../../
      dockerfile: .docker/dev/Dockerfile
    working_dir: /app
    volumes:
      - ../../:/app
      - node_modules:/app/node_modules
    command: sh -c "npm install --no-audit --no-fund && npm run dev"
    ports:
      - "${APP_PORT}:3000"
EOF

if [[ "$USE_POSTGRES" =~ ^[Yy]$ ]]; then

cat >> "$COMPOSE_FILE" <<'EOF'

  postgres:
    image: postgres:15
    restart: always
    volumes:
      - ../../.docker/data/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT}:5432"
EOF

fi

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then

cat >> "$COMPOSE_FILE" <<'EOF'

  redis:
    image: redis:7
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - ../../.docker/data/redis:/data
EOF

fi

if [[ "$USE_REDIS_COMMANDER" =~ ^[Yy]$ ]]; then

cat >> "$COMPOSE_FILE" <<'EOF'

  redis-commander:
    image: rediscommander/redis-commander
    depends_on:
      - redis
    environment:
      REDIS_HOST: redis
    ports:
      - "${REDIS_COMMANDER_PORT}:8081"
EOF

fi

if [[ "$USE_PGADMIN" =~ ^[Yy]$ ]]; then

cat >> "$COMPOSE_FILE" <<'EOF'

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD}
    ports:
      - "${PGADMIN_PORT}:80"
    volumes:
      - ../../.docker/data/pgadmin:/var/lib/pgadmin
EOF

fi

cat >> "$COMPOSE_FILE" <<'EOF'

  prisma-studio:
    build:
      context: ../../
      dockerfile: .docker/dev/Dockerfile
    volumes:
      - ../../:/app
      - node_modules:/app/node_modules
    command: sh -c "npx prisma generate && BROWSER=none npx prisma studio --port 5555"
    ports:
      - "${PRISMA_STUDIO_PORT}:5555"

volumes:
  node_modules:
EOF

}

create_env() {

APP_PORT=$(find_port 3000)
PRISMA_STUDIO_PORT=$(find_port 5555)

POSTGRES_PORT=$(find_port 5432)
REDIS_PORT=$(find_port 6379)
PGADMIN_PORT=$(find_port 5050)
REDIS_COMMANDER_PORT=$(find_port 8081)

POSTGRES_PASSWORD=$(openssl rand -hex 12)
PGADMIN_PASSWORD=$(openssl rand -hex 12)

cat > "$ENV_FILE" <<EOF
APP_PORT=$APP_PORT
PRISMA_STUDIO_PORT=$PRISMA_STUDIO_PORT

POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_PORT=$POSTGRES_PORT

PGADMIN_EMAIL=admin@localhost.com
PGADMIN_PASSWORD=$PGADMIN_PASSWORD
PGADMIN_PORT=$PGADMIN_PORT

REDIS_PORT=$REDIS_PORT
REDIS_COMMANDER_PORT=$REDIS_COMMANDER_PORT

DATABASE_URL=postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/app?schema=public
EOF

}

setup_project_readme() {

echo -e "${YELLOW}▶ Setting project README...${NC}"

if [ -f README.project.md ]; then
cp README.project.md README.md
rm README.project.md
fi

}

show_success() {

source "$ENV_FILE"

echo
echo -e "${GREEN}Project ready${NC}"
echo

echo "Next.js → http://localhost:$APP_PORT"
echo "Prisma Studio → http://localhost:$PRISMA_STUDIO_PORT"
echo "pgAdmin → http://localhost:$PGADMIN_PORT"
echo "Redis Commander → http://localhost:$REDIS_COMMANDER_PORT"
echo

echo "Start dev environment:"
echo "./dev.sh rebuild"
echo
}

print_banner
detect_docker_compose
check_dependencies
ensure_empty_project
ask_services
create_nextjs_project
install_prisma
create_structure
create_dockerfile
create_docker_compose
create_env
setup_project_readme
show_success