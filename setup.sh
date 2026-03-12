#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_banner() {

echo
echo "🚀 Next.js Docker Project Setup"
echo

PROJECT_NAME=$(basename "$PWD")

echo "Project: $PROJECT_NAME"
echo

}

print_system_info() {

echo "Environment"
echo "Docker: $(docker --version)"
echo "Node: $(node --version)"
echo

}

detect_docker_compose() {

if command -v docker-compose &> /dev/null; then
DOCKER_COMPOSE="docker-compose"
else
DOCKER_COMPOSE="docker compose"
fi

}

check_docker_installed() {

if ! command -v docker &> /dev/null; then
echo -e "${RED}Docker is not installed.${NC}"
echo
echo "Install Docker:"
echo "https://docs.docker.com/get-docker/"
exit 1
fi

}

check_docker_running() {

if ! docker info &> /dev/null; then
echo -e "${RED}Docker is not running.${NC}"
echo "Please start Docker and try again."
exit 1
fi

}

check_node_installed() {

if ! command -v node &> /dev/null; then
echo -e "${RED}Node.js is not installed.${NC}"
echo
echo "Install Node.js:"
echo "https://nodejs.org"
exit 1
fi

}

check_npx_installed() {

if ! command -v npx &> /dev/null; then
echo -e "${RED}npx is not available.${NC}"
echo
echo "Please install Node.js LTS which includes npx."
exit 1
fi

}

check_openssl_installed() {

if ! command -v openssl &> /dev/null; then
echo -e "${RED}openssl is not installed.${NC}"
echo
echo "Install openssl and try again."
exit 1
fi

}

ensure_empty_project() {

if [ -f "package.json" ]; then
echo -e "${RED}A project already exists in this directory.${NC}"
echo "Run this script in a new directory."
exit 1
fi

}

ask_services() {

echo
echo "Select optional services:"
echo

read -p "Include PostgreSQL? (Y/n): " USE_POSTGRES
read -p "Include Redis? (Y/n): " USE_REDIS
read -p "Include pgAdmin? (Y/n): " USE_PGADMIN
read -p "Include Redis Commander? (Y/n): " USE_REDIS_COMMANDER

USE_POSTGRES=${USE_POSTGRES:-Y}
USE_REDIS=${USE_REDIS:-Y}
USE_PGADMIN=${USE_PGADMIN:-Y}
USE_REDIS_COMMANDER=${USE_REDIS_COMMANDER:-Y}

# pgAdmin requires PostgreSQL
if [[ ! "$USE_POSTGRES" =~ ^[Yy]$ && "$USE_PGADMIN" =~ ^[Yy]$ ]]; then
echo "pgAdmin requires PostgreSQL. Disabling pgAdmin."
USE_PGADMIN="n"
fi

# Redis Commander requires Redis
if [[ ! "$USE_REDIS" =~ ^[Yy]$ ]]; then
echo "Redis Commander requires Redis. Disabling Redis Commander."
USE_REDIS_COMMANDER="n"
fi

}

is_port_used() {

local port=$1

if command -v lsof &> /dev/null; then
lsof -i :$port &>/dev/null
return $?
elif command -v ss &> /dev/null; then
ss -tuln | grep -q ":$port "
return $?
else
return 1
fi

}

find_available_port() {

local port=$1

while is_port_used $port; do
port=$((port+1))
done

echo $port

}

create_nextjs_project() {

echo -e "${YELLOW}▶ Creating Next.js project...${NC}"

npx create-next-app@latest temp-next-app \
--typescript \
--tailwind \
--eslint \
--app \
--src-dir \
--import-alias "@/*" \
--use-npm \
--yes

echo -e "${YELLOW}▶ Moving project files...${NC}"

shopt -s dotglob
mv temp-next-app/* .
shopt -u dotglob

rm -rf temp-next-app
rm -rf .git

# remove host artifacts
rm -rf node_modules
rm -rf .next
rm -f package-lock.json

echo -e "${GREEN}✓ Next.js project created${NC}"

}

fix_docker_permissions() {

if [ -d ".docker" ]; then
if [ ! -w ".docker" ]; then
echo -e "${YELLOW}▶ Fixing .docker permissions...${NC}"
sudo chown -R "$USER":"$USER" .docker 2>/dev/null || true
fi
fi

}

create_structure() {

echo -e "${YELLOW}▶ Creating project structure...${NC}"

mkdir -p .docker/dev
mkdir -p .docker/data/postgres
mkdir -p .docker/data/redis
mkdir -p .docker/data/pgadmin

chmod -R 777 .docker/data

}

create_dockerignore() {

echo -e "${YELLOW}▶ Creating .dockerignore...${NC}"

cat <<EOF > .dockerignore
node_modules
.next
.git
.gitignore
.env
.docker/data
Dockerfile
docker-compose.yml
EOF

}

create_dockerfile() {

echo -e "${YELLOW}▶ Creating Dockerfile...${NC}"

cat <<EOF > .docker/dev/Dockerfile
FROM node:22-slim

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm","run","dev"]
EOF

}

create_docker_compose() {

echo -e "${YELLOW}▶ Creating docker-compose.yml...${NC}"

DEPENDS=""

if [[ "$USE_POSTGRES" =~ ^[Yy]$ ]]; then
DEPENDS="$DEPENDS
      - postgres"
fi

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
DEPENDS="$DEPENDS
      - redis"
fi

cat <<EOF > .docker/dev/docker-compose.yml
services:

  app:
    build:
      context: ../../
      dockerfile: .docker/dev/Dockerfile
    volumes:
      - ../../:/app
      - node_modules:/app/node_modules
    ports:
      - "\${APP_PORT}:3000"
EOF

if [ -n "$DEPENDS" ]; then
cat <<EOF >> .docker/dev/docker-compose.yml
    depends_on:$DEPENDS
EOF
fi

if [[ "$USE_POSTGRES" =~ ^[Yy]$ ]]; then
cat <<EOF >> .docker/dev/docker-compose.yml

  postgres:
    image: postgres:15
    restart: always
    volumes:
      - ../../.docker/data/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    ports:
      - "\${POSTGRES_PORT}:5432"

EOF
fi

if [[ "$USE_PGADMIN" =~ ^[Yy]$ ]]; then
cat <<EOF >> .docker/dev/docker-compose.yml

  pgadmin:
    image: dpage/pgadmin4
    restart: always
    environment:
      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_PASSWORD}
    ports:
      - "\${PGADMIN_PORT}:80"
    volumes:
      - ../../.docker/data/pgadmin:/var/lib/pgadmin

EOF
fi

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
cat <<EOF >> .docker/dev/docker-compose.yml

  redis:
    image: redis:7
    ports:
      - "\${REDIS_PORT}:6379"
    volumes:
      - ../../.docker/data/redis:/data

EOF
fi

if [[ "$USE_REDIS_COMMANDER" =~ ^[Yy]$ ]]; then
cat <<EOF >> .docker/dev/docker-compose.yml

  redis-commander:
    image: rediscommander/redis-commander
    depends_on:
      - redis
    ports:
      - "\${REDIS_COMMANDER_PORT}:8081"

EOF
fi

cat <<EOF >> .docker/dev/docker-compose.yml

volumes:
  node_modules:

EOF

}

create_env() {

echo -e "${YELLOW}▶ Creating .env file...${NC}"

APP_PORT=$(find_available_port 3000)
if [[ "$USE_POSTGRES" =~ ^[Yy]$ ]]; then
POSTGRES_PORT=$(find_available_port 5432)
PGADMIN_PORT=$(find_available_port 5050)
fi

if [[ "$USE_REDIS" =~ ^[Yy]$ ]]; then
REDIS_PORT=$(find_available_port 6379)
REDIS_COMMANDER_PORT=$(find_available_port 8081)
fi

POSTGRES_PASSWORD=$(openssl rand -hex 12)
PGADMIN_PASSWORD=$(openssl rand -hex 12)

cat <<EOF > .env
APP_PORT=$APP_PORT

POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_PORT=$POSTGRES_PORT

PGADMIN_EMAIL=admin@localhost.com
PGADMIN_PASSWORD=$PGADMIN_PASSWORD
PGADMIN_PORT=$PGADMIN_PORT

REDIS_PORT=$REDIS_PORT
REDIS_COMMANDER_PORT=$REDIS_COMMANDER_PORT
EOF

}

install_dev_script() {

echo -e "${YELLOW}▶ Installing dev.sh...${NC}"
chmod +x dev.sh

}

setup_project_readme() {

echo -e "${YELLOW}▶ Setting project README...${NC}"

if [ -f README.project.md ]; then
cp README.project.md README.md
rm README.project.md
fi

}

show_success() {

source .env
PROJECT_NAME=$(basename "$PWD")

echo
echo -e "${GREEN}✅ Project '$PROJECT_NAME' successfully created!${NC}"
echo
echo "Start development:"
echo
echo "./dev.sh rebuild"
echo
echo "Check running services:"
echo
echo "./dev.sh ports"
echo
echo "Application:"
echo "http://localhost:$APP_PORT"

if [[ "$USE_PGADMIN" =~ ^[Yy]$ ]]; then
echo
echo "pgAdmin:"
echo "http://localhost:$PGADMIN_PORT"
fi

if [[ "$USE_REDIS_COMMANDER" =~ ^[Yy]$ ]]; then
echo
echo "Redis Commander:"
echo "http://localhost:$REDIS_COMMANDER_PORT"
fi

echo

}

print_banner
print_system_info
detect_docker_compose
check_docker_installed
check_docker_running
check_node_installed
check_npx_installed
check_openssl_installed
ensure_empty_project
ask_services
create_nextjs_project
fix_docker_permissions
create_structure
create_dockerignore
create_dockerfile
create_docker_compose
create_env
install_dev_script
setup_project_readme
show_success