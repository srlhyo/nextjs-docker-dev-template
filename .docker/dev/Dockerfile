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
