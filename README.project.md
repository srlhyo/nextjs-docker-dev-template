# README.project.md — Generated Project

# Project

This project was generated using the **Next.js Docker Development Template**.

It provides a **fully containerized development environment** for building Next.js applications.

---

# Development Stack

Your environment may include:

* Next.js
* Prisma ORM
* Prisma Studio
* PostgreSQL
* Redis
* pgAdmin
* Redis Commander

All services run inside Docker containers.

---

# Start Development

```
./dev.sh rebuild
```

---

# Check Running Services

```
./dev.sh ports
```

Example:

```
Next.js → http://localhost:3001
Prisma Studio → http://localhost:5555
pgAdmin → http://localhost:5050
Redis Commander → http://localhost:8082
```

---

# Prisma ORM

Prisma manages the database layer.

Schema location:

```
prisma/schema.prisma
```

Database connection:

```
.env
```

---

# Useful Commands

Start environment

```
./dev.sh start
```

Stop environment

```
./dev.sh stop
```

Rebuild containers

```
./dev.sh rebuild
```

View logs

```
./dev.sh logs
```

Reset environment

```
./dev.sh reset
```

---

# Notes

* All services run inside Docker containers
* Your system stays clean (no local databases required)
* Ports automatically adjust if defaults are in use
* Optional services may be disabled depending on setup choices
