![Safebox Logo](./resources/safebox_logo.svg)

# Framework Scheduler

The framework-scheduler is a component of the Safebox project, which is designed to manage and schedule tasks within a containerized environment.

## Descriptions

Framework Scheduler is a lightweight Alpine-based container that provides task scheduling and service management capabilities. It includes network scanning, service discovery, certificate management, and automated backup functionality for challenge clients.

### Dependencies
The framework-scheduler is a part of the Safebox platform. For the full functionality it is needed the safebox/web-installer image also.
You can find the current version of the web-installer image on [Docker Hub](https://hub.docker.com/r/safebox/web-installer). The source code repository you can find here: https://git.format.hu/safebox/web-installer

## Screenshots

*Screenshots will be added as the project develops*

## How to Use

## Running the Container

```bash
  docker run \
  --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  safebox/framework-scheduler:latest
```

## Build your own image
To build the framework-scheduler image from the source code, follow these steps:
1. Clone the repository:
   ```bash
   git clone https://git.format.hu/safebox/framework-scheduler.git
   cd framework-scheduler
   ```
2. Build the Docker image:
   ```bash
   docker build -t <your docker registry>/framework-scheduler:latest .
   ```
3. Run the container:
   ```bash
   docker run --rm -e DOCKER_REGISTRY_URL='<your docker registry>' -v /var/run/docker.sock:/var/run/docker.sock framework-scheduler:latest
   ```
Keep in mind to replace `<your docker registry>` with your actual Docker registry URL because the image will use the fallback docker registry url as 'safebox' .