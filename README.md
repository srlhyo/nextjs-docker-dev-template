# Next.js Docker Development Template

Create a **complete web development environment in minutes**.

This template automatically creates a project with:

* Next.js (web framework)
* PostgreSQL (database)
* Redis (cache)
* pgAdmin (database management UI)
* Redis Commander (Redis UI)
* Docker containers for isolated development

Everything runs inside Docker so it **does not affect your system**.

---

# Works On

This template has been tested on:

* macOS
* Linux
* Windows (WSL)

---

# Requirements

Install these first.

## 1. Docker

Download and install:

[https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

Verify installation:

```bash
docker --version
```

Docker must be **running** before starting the environment.

---

## 2. Node.js

Download:

[https://nodejs.org](https://nodejs.org)

Verify installation:

```bash
node --version
```

Node.js LTS is recommended.

---

# Step 1 — Create a Project From This Template

Clone the template repository:

```bash
git clone https://github.com/YOUR-USERNAME/dev-env-template my-project
```

Enter the project folder:

```bash
cd my-project
```

Make the scripts executable:

```bash
chmod +x setup.sh dev.sh
```

Run the setup script:

```bash
./setup.sh
```

This will automatically:

* create a Next.js project
* configure Docker
* configure PostgreSQL
* configure Redis
* generate environment variables
* prepare the development environment

---

# Step 2 — Start the Development Environment

Build the containers:

```bash
./dev.sh rebuild
```

Start the environment:

```bash
./dev.sh start
```

---

# Step 3 — Open the Applications

Ports may change automatically if your system already uses the default ones.

Run this command to see the correct URLs:

```bash
./dev.sh ports
```

Example output:

```
Next.js → http://localhost:3000
pgAdmin → http://localhost:5050
Redis Commander → http://localhost:8081
```

Open the URLs shown in your browser.

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

# Create a GitHub Repository for Your Project

After the project is created, you can connect it to GitHub.

Create a new repository on GitHub, then run:

```bash
git init
git add .
git commit -m "Initial project"

git remote add origin https://github.com/YOUR-USERNAME/YOUR-PROJECT.git
git branch -M main
git push -u origin main
```

---

# Troubleshooting

If something breaks:

```bash
./dev.sh reset
./dev.sh rebuild
```

You can also check your system setup:

```bash
./dev.sh doctor
```

---

# What This Template Creates

Your generated project will include:

* Next.js application
* Docker development environment
* PostgreSQL database
* Redis cache
* pgAdmin interface
* Redis Commander interface
* automated environment configuration

---

# License

MIT License
