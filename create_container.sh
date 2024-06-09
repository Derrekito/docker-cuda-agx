#!/bin/bash

# Prompt the user to provide the path for LOCAL_DIR
read -p "Please enter the path for LOCAL_DIR: " LOCAL_DIR

# Check if LOCAL_DIR is provided
if [ -z "$LOCAL_DIR" ]; then
    echo "Error: LOCAL_DIR path is required."
    exit 1
fi

CONTAINER_DIR="/shared"

IMAGE_TAG="cudatools:11.8"
CONTAINER_NAME="cudatools-11.8"

docker run -it --hostname orin-compiler -v $LOCAL_DIR:$CONTAINER_DIR -v apt-cache:/var/cache/apt/archives --name $CONTAINER_NAME $IMAGE_TAG
