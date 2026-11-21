![Safebox Logo](./resources/safebox_logo.svg)
# Framework Scheduler

The Framework Scheduler is a component of the Safebox project, designed to manage and schedule tasks within a containerized environment.

## Description

Framework Scheduler is a lightweight, Alpine-based container that provides task scheduling and service management capabilities. It includes network scanning, service discovery, certificate management, and automated backup functionality for challenge clients.

### Dependencies
The Framework Scheduler is part of the Safebox platform. For full functionality, it also requires the `safebox/web-installer` image.
You can find the current version of the web-installer image on [Docker Hub](https://hub.docker.com/r/safebox/web-installer). The source code repository is available at [https://github.com/safeboxnetwork/web-installer](https://github.com/safeboxnetwork/web-installer).

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

 ><p align=justify><i><b>Keep in mind!</b> that the Safebox platfrom requires an isolated Docker network which is automatically created when you run the `safebox/framework-scheduler` image for the first time. While running the container, it will check for the existence of this network and create it if it does not exist and also check the desired subnet availability. If you would like to specify a custom subnet for the Safebox network, you can set the <code>FRAMEWORK_SCHEDULER_NETWORK_SUBNET</code> environment variable when running the container or set the <code>RUN_FORCE=true</code> environment variable to force the creation of the network even if the desired subnet is not available.</i></p>


### Alternative way to deploy via command line
```bash
curl https://raw.githubusercontent.com/safeboxnetwork/framework-scheduler/refs/heads/main/development/installer.sh | bash
```

**Please note:** This method is recommended only for quick tests and development purposes. Avoid using it in production environments.

### Accessing the Web Interface
Once the container is running, you can access the web interface by navigating to `http://<host-ip>:8080` in your web browser. Replace `<host-ip>` with the IP address of the host machine where the container is running.

### Build Your Own Image
To build the Framework Scheduler image from the source code, follow these steps:
1. Clone the repository:
     ```bash
     git clone https://github.com/safebox/framework-scheduler.git
     cd framework-scheduler
     ```
2. Build the Docker image:
     ```bash
     docker build -t <your-docker-registry>/framework-scheduler:latest .
     ```
3. Run the container:
     ```bash
     docker run --rm -e DOCKER_REGISTRY_URL=<your-docker-registry> -v /var/run/docker.sock:/var/run/docker.sock <your-docker-registry>/framework-scheduler:latest
     ```
     > **Note:** Replace `<your-docker-registry>` with your actual Docker registry URL. Otherwise, the image will use the default Docker registry URL, 'safebox'.

### Environment Variables

The following environment variables can be set to configure the Framework Scheduler. These are defined as usable global environments at the beginning of `scripts/scheduler/entrypoint.sh` and are exported to all child containers and services:

#### Core Configuration

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `DEBUG_MODE` | `false` | Enables debug mode when set to `true`. |
| `VERSION` | `1.2.1` | The Framework Scheduler version. |
| `DOCKER_REGISTRY_URL` | `safebox` | Docker registry URL for image operations. Required for pushing to a private registry. |
| `DOCKER_REGISTRY_USERNAME` | (none) | Username for Docker registry authentication. |
| `DOCKER_REGISTRY_PASSWORD` | (none) | Password for Docker registry authentication. |
| `GLOBAL_VERSION` | `latest` | Global version tag used for service images. |
| `GIT_URL` | `github.com` | Git server URL used for cloning service repositories. |
| `ORGANIZATION` | `safeboxnetwork` | Organization name on the Git server used for repository paths. |

#### Directory Paths

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `SERVICE_DIR` | `/etc/user/config/services` | Directory containing service configuration JSON files. |
| `SECRET_DIR` | `/etc/user/secret` | Directory for storing secrets. |
| `SHARED` | `/var/tmp/shared` | Shared directory for inter-container data exchange. |

#### Framework Scheduler Settings

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `FRAMEWORK_SCHEDULER_IMAGE` | `framework-scheduler` | Image name for the Framework Scheduler container. |
| `FRAMEWORK_SCHEDULER_NAME` | `framework-scheduler` | Container name for the Framework Scheduler. |
| `FRAMEWORK_SCHEDULER_NETWORK` | `framework-network` | Docker network name used by Safebox services. |
| `FRAMEWORK_SCHEDULER_NETWORK_SUBNET` | `172.19.255.0/24` | Subnet CIDR for the Safebox Docker network. |
| `FRAMEWORK_SCHEDULER_VERSION` | `latest` | Version tag for the Framework Scheduler image. |
| `RUN_FORCE` | `false` | Forces creation of the Docker network even if the desired subnet is unavailable. |

#### Web Interface & Redis

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `WEB_SERVER` | `webserver` | Service name for the web server container. |
| `WEB_IMAGE` | `web-installer` | Image name for the web installer service. |
| `WEBSERVER_PORT` | `8080` | Port number for the web interface. |
| `WEBSERVER_VERSION` | `latest` | Version tag for the web installer image. |

> **Note:** Variables without a default value are passed through from the container environment if set; otherwise they remain empty.

## TODO
The Framework Scheduler is under active development. Future plans include:
- Backup and restore functionality for challenge clients with different users' Safebox platforms.
- Enhanced monitoring and alerting features.
- Enhanced disk space management and alerting features.
- Notifications for better performance and management of your installed applications.

## White Paper
[Read the White Paper](WHITE_PAPER.md)