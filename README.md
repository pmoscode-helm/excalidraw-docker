# Excalidraw Docker

This repository provides a Docker-based setup to run the web application [**Excalidraw**](https://github.com/excalidraw/excalidraw) in a containerized environment, which differs in one aspekt: The hard coded collab server URL can be customized.  

---

## Repository Structure

- `Dockerfile` – Defines the build process for Excalidraw.
- `docker-compose.yml` – Configuration for Docker Compose to orchestrate the app and its services.
- `nginx-init-scripts/` – Scripts for initializing and configuring Nginx (override the hard coded server URL).
- `Taskfile.yaml` – Automates build and development tasks.
- `.github/workflows/` – CI/CD workflows for automating tests and deployments.

---

## Usage

You can start Excalidraw using the provided Docker and Docker Compose configurations:

### Using Docker Compose

```bash
docker-compose up
```

Directly with Docker

```bash
docker build -t excalidraw .
docker run -p 3000:3000 excalidraw
```

This starts Excalidraw on port 3000.
