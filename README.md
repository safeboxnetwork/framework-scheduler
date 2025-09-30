![Safebox Logo](./resources/safebox_logo.svg)

# Framework Scheduler

The framework-scheduler is a component of the Safebox project, which is designed to manage and schedule tasks within a containerized environment.

## Descriptions

Framework Scheduler is a lightweight Alpine-based container that provides task scheduling and service management capabilities. It includes network scanning, service discovery, certificate management, and automated backup functionality for challenge clients.

### Dependencies
The framework-scheduler is a part of the Safebox platform. For the full functionality it is needed the safebox/web-installer image also.
You can find the current version of the web-installer image on [Docker Hub](https://hub.docker.com/r/safebox/web-installer). The source code repository you can find here: https://git.format.hu/safebox/web-installer

## Screenshots
![Framework Scheduler Screenshot](./resources/framework_scheduler_main.png)

## How to Use

### Running the Container

```bash
  docker run \
  --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  safebox/framework-scheduler:latest
```

### Build your own image
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
   docker run --rm -e DOCKER_REGISTRY_URL=<your docker registry> -v /var/run/docker.sock:/var/run/docker.sock <your docker registry>/framework-scheduler:latest
   ```
Keep in mind to replace `<your docker registry>` with your actual Docker registry URL because the image will use the fallback docker registry url as 'safebox' .

### Environment Variables
The following environment variables can be set to configure the framework-scheduler:
If you want to push the image to a private docker registry you need to set these environment variables:
| Environment Variable | Description |
|---------------------|-------------|
| DOCKER_REGISTRY_URL | Docker registry URL for image operations |
| DOCKER_REGISTRY_USERNAME | Username for Docker registry authentication |
| DOCKER_REGISTRY_PASSWORD | Password for Docker registry authentication 

The framework-scheduler web interface used the localhost 8080 port by default, you can change it with this environment variable:
| Environment Variable | Description |
|---------------------|-------------|
| WEBSERVER_PORT | Port number for the web interface. Default: 8080. |

## TODO
The framework-scheduler is under active development. Future plans include:
- Backup and restore functionality for challenge clients with different users' safebox platforms.
- Enhanced monitoring and alerting features.
- Enhanced disk space management and alerting features also.