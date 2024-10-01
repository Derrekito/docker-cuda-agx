# Docker-CUDA-AGX
Docker development environment for the NVIDIA Jetson AGX
- Compatible for development for the NVIDIA Jetson Orin NX

This includes Jsoncpp with the installation. Please refer to the following instructions for installing the Docker Engine, setting up the Docker CUDA AGX, and liblog. 

## Installing Docker Engine on Ubuntu

For more information, visit the [dockerdocs](https://docs.docker.com/engine/install/ubuntu/).

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

For more information, visit the [dockerdocs-post-installation](https://docs.docker.com/engine/install/linux-postinstall/).

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

## Docker Cuda AGX

Get the master branch of [docker-cuda-agx](https://github.com/Derrekito/docker-cuda-agx).

```bash
git clone git@github.com:Derrekito/docker-cuda-agx.git
cd docker-cuda-agx
``` 
Run the `build_image`:

```bash
./build_image.sh
```

Run the `create_container` and give a `path/to/projects` directory of your preference: 

```bash
./create_container.sh
```

Run `run_container.sh` to run your environment: 

```bash
./run_container.sh
```

## Liblog Installation

Get the master branch of [liblog](https://github.com/Derrekito/liblog).

```bash
git clone git@github.com:Derrekito/liblog.git
```
Change directories into the cloned repository: 

```bash
cd liblog/
```
Run `make install` to install liblog:
- You may be required to run this with `sudo`.

```bash
make install
```
Run `ldconfig`: 

```bash 
ldconfig
```