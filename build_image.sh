#!/bin/bash

TAG="cudatools:11.8"

KEYRING="cuda-keyring_1.0-1_all.deb"
CUDA_REPO_INSTALLER="cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb"
GPGKEY="3bf863cc.pub"
BASE_URL="https://developer.download.nvidia.com/compute/cuda"

function dl()
{
    wget -nc $1
}

dl "${BASE_URL}/repos/ubuntu2004/x86_64/$KEYRING"
dl "${BASE_URL}/11.8.0/local_installers/${CUDA_REPO_INSTALLER}"
dl "${BASE_URL}/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin"
dl "${BASE_URL}/repos/ubuntu2004/cross-linux-aarch64/${GPGKEY} -O ${GPGKEY}"

git clone https://github.com/xianyi/OpenBLAS.git
git clone https://github.com/open-source-parsers/jsoncpp.git

docker build --tag "$TAG" --build-arg APT_CACHE_VOLUME=apt-cache .

