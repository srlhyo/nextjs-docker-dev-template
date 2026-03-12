# Next.js Docker Development Template

Create a **complete web development environment in minutes**.

This template automatically generates a project with:

* Next.js
* Docker development environment
* PostgreSQL (optional)
* Redis (optional)
* pgAdmin (optional)
* Redis Commander (optional)

Everything runs inside Docker so it **does not affect your system**.

---

# Step 1 — Create a Project From This Template

On the GitHub page of this repository click:

```
Use this template
```

Then:

1. Choose a **repository name** (this becomes your project name)
2. Choose **public or private**
3. Click **Create repository**

GitHub will generate a new repository based on this template.

---

# Step 2 — Clone Your Project

Clone the repository you just created:

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-PROJECT
cd YOUR-PROJECT
```

Make scripts executable:

```bash
chmod +x setup.sh dev.sh
```

---

# Step 3 — Verify Requirements

Before running the setup script, verify that required tools are installed.

## Docker

Check Docker:

```bash
docker --version
```

If Docker is not installed:

[https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

Docker must be **running** before continuing.

---

## Node.js

Check Node.js:

```bash
node --version
```

If Node.js is not installed:

[https://nodejs.org](https://nodejs.org)

---

# Step 4 — Run Project Setup

Run the setup script:

```bash
./setup.sh
```

This script will automatically:

* create a Next.js project
* configure Docker
* configure optional services
* generate environment variables
* prepare the development environment

---

# Step 5 — Start Development

Build and start the development environment:

```bash
./dev.sh rebuild
```

This command builds the containers and starts all services.

To see the service URLs:

```bash
./dev.sh ports
```

---

# Useful Commands

Start containers

```bash
./dev.sh start
```

Stop containers

```bash
./dev.sh stop
```

Rebuild containers

```bash
./dev.sh rebuild
```

View logs

```bash
./dev.sh logs
```

Check environment health

```bash
./dev.sh doctor
```

Reset the environment

```bash
./dev.sh reset
```

---

# What This Template Creates

Your generated project will include:

* Next.js application
* Docker development environment
* PostgreSQL database (optional)
* Redis cache (optional)
* pgAdmin interface (optional)
* Redis Commander interface (optional)

---

# License

MIT License
