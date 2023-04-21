#!/bin/bash

LOCAL_DIR="/home/derrekito/Projects/SpaceBench"
CONTAINER_DIR="/shared"

IMAGE_TAG="cudatools:11.8"
CONTAINER_NAME="cudatools-11.8"

docker run -it -v $LOCAL_DIR:$CONTAINER_DIR -v apt-cache:/var/cache/apt/archives --name $CONTAINER_NAME $IMAGE_TAG
