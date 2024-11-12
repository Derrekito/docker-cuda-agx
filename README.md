# Docker-CUDA-Orin-Series
Docker development environment for the NVIDIA Jetson Orin Series (Nano, NX, and AGX).

This Docker development environment is designed for the NVIDIA Jetson Orin Series (Nano, NX, and AGX). It is purposed for developmental purposes, supporting a variety of projects for these devices, and providing custom-compiled support libraries such as JsonCpp and OpenBLAS. The environment utilizes CUDA version 11.8. 

JsonCpp and OpenBLAS are cloned and included in this Docker development environment by running `build_image.sh`. The following sections explain how to install [Installing Docker Engine on Ubuntu](#installing-docker-engine-on-ubuntu) and [Linux post-installation steps for Docker Engine](#linux-post-installion-steps-for-docker-engine) for the Docker Engine and setup [Docker Cuda Setup](#docker-cuda-setup) for the Docker CUDA Orin Series. 

## Installing Docker Engine on Ubuntu

The following instructions are abstracted and summarized, please visit [dockerdocs](https://docs.docker.com/engine/install/ubuntu/) for more information.

Install using the **apt** repository: 

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```
Install the lastest version:

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Ensure the Docker Engine installation is successful by running the `hello-world` image:

```bash
sudo docker run hello-world
```

### Linux post-installion steps for Docker Engine

The following instructions are abstracted and summarized, please visit [dockerdocs-post-installation](https://docs.docker.com/engine/install/linux-postinstall/) for more information.

Create the docker group and add your user: 

1. Create the docker group:
    ```bash
    sudo groupadd docker
    ```
2. Add your user to the docker group:
    ```bash
    sudo usermod -aG docker $USER
    ```
3. Log out and log back in from your device so your group membership is re-evaluated. 
    - To activate changes to the group, run: 
        ```bash
        newgrp docker
        ```
4. Verify that docker works: 
    ```bash
    docker run hello-world
    ```

## Docker CUDA Setup

Clone the master branch.

```bash
git clone git@github.com:Derrekito/docker-cuda-agx.git
cd docker-cuda-agx
``` 
Run the `build_image` to build the image:
- `build_image` downloads necessary files, clones the OpenBLAS and JsonCpp repositories, and builds the Docker image with the tag "cudatools:11.8".
```bash
./build_image.sh
```

Run the `create_container` and give a `path/to/projects` directory of your preference: 
- `create_container` creates a Docker container from the built image and mounts the specified directory to the container.
```bash
./create_container.sh
```

Run `run_container.sh` to run your environment:
- `run_container.sh` starts the Docker container, providing an isolated environment with all the necessary tools and libraries pre-installed.
```bash
./run_container.sh
```