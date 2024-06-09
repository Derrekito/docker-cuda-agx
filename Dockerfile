# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Set version label with build arguments
ARG BUILD_DATE
ARG VERSION
LABEL build_version="AGX dev env version:- ${VERSION} build-date:- ${BUILD_DATE}"
LABEL maintainer="derrekito"

ENV NVIDIA_VERSION="11.8"
ENV GCC_VERSION="11"

# Set the TERM environment variable to linux
ENV TERM linux

# Configure debconf for noninteractive frontend
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Create a script that does nothing to prevent starting services during package installation
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Mount the cache volume to the container's /var/cache/apt/archives directory
VOLUME [ "/var/cache/apt/archives" ]

# Update package list, install apt-utils, wget, and ca-certificates
RUN apt-get update -y && apt-get install -y apt-utils wget ca-certificates

# Add the arm64 architecture to the system
RUN dpkg --add-architecture aarch64

# Update the system and install necessary tools
RUN apt-get update -y && apt-get install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y
RUN apt-get update -y && \
    apt-get install -y \
    build-essential \
    gcc-11 \
    g++-11 \
    git

# Add the NVIDIA CUDA repository GPG key and repository, and install CUDA toolkit
COPY cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb /tmp/
COPY cuda-ubuntu2004.pin /tmp/

RUN apt-get update -y && \
    dpkg -i /tmp/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb && \
    mv /tmp/cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    cp /var/cuda-repo-ubuntu2004-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update -y && \
    apt-get -y install cuda-toolkit-11-8 && \
    rm /tmp/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb

# Update the system and install necessary tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg

# Add the 22.04 repository for the specific package
#RUN echo "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list.d/jammy.list && \
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F

# Install the specific package from the 22.04 repository
#RUN apt-get update && apt-get install -y --no-install-recommends gcc-11-aarch64-linux-gnu g++-11-aarch64-linux-gnu gfortran-11-aarch64-linux-gnu gcc-doc
RUN apt-get update && apt-get install -y --no-install-recommends gcc-aarch64-linux-gnu g++-aarch64-linux-gnu gfortran-aarch64-linux-gnu gcc-doc

# Add the NVIDIA CUDA repository GPG key
ENV GPGKEY="3bf863cc.pub"
ENV CROSS_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/cross-linux-aarch64"
#RUN wget ${CROSS_URL}/${GPGKEY} -O ${GPGKEY} \
COPY ${GPGKEY} /tmp/
RUN apt-key add /tmp/${GPGKEY} && \
    rm /tmp/${GPGKEY}

# Add the repository to the system's sources list
RUN echo "deb ${CROSS_URL} /" > /etc/apt/sources.list.d/cuda-cross-aarch64.list

# Update the package lists for the newly added repository
RUN apt-get update -y && apt-get install -y cuda-cross-aarch64-11-8

# Set the PATH environment variable to include CUDA binaries
ENV PATH="/usr/local/cuda-${NVIDIA_VERSION}/bin:${PATH}"

# Set the LD_LIBRARY_PATH environment variable to include CUDA libraries
ENV export LD_LIBRARY_PATH="/usr/local/cuda-${NVIDIA_VERSION}/lib:$LD_LIBRARY_PATH"

# build OpenBLAS
ENV MAX_NUM_THREADS=12
ENV OPENBLAS_NUM_THREADS=$MAX_NUM_THREADS
ENV GOTO_NUM_THREADS=$MAX_NUM_THREADS
ENV OMP_NUM_THREADS=$MAX_NUM_THREADS

# copy OpenBLAS repo to tmp
COPY OpenBLAS /tmp/OpenBLAS
#USER root
RUN chown -R ${USER}:${USER} /tmp/OpenBLAS
WORKDIR /tmp/OpenBLAS

# clean up the build environment as a precaution
RUN make clean

# Build OpenBLAS with the ARM GCC and gfortran compilers, targeting ARM64 and using OpenMP
# specific target not yet supported, fall back to ARMV8
#    make CC=aarch64-linux-gnu-gcc-11 FC=aarch64-linux-gnu-gfortran-11 HOSTCC=gcc-11 TARGET=CORTEXA78AE USE_OPENMP=1

# Build for a closer micro arch
#RUN make CC=aarch64-linux-gnu-gcc-11 FC=aarch64-linux-gnu-gfortran-11 HOSTCC=gcc-11 TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=ranlib
RUN make CC=aarch64-linux-gnu-gcc FC=aarch64-linux-gnu-gfortran HOSTCC=gcc TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=ranlib

# Build for a generic ARMV8 target
#RUN make CC=aarch64-linux-gnu-gcc-11 FC=aarch64-linux-gnu-gfortran-11 HOSTCC=gcc-11 TARGET=ARMV8 USE_OPENMP=1 RANLIB=ranlib

# Install OpenBLAS under /usr/local
#RUN make PREFIX=/usr/local install
#RUN make CC=aarch64-linux-gnu-gcc-11 FC=aarch64-linux-gnu-gfortran-11 HOSTCC=gcc-11 TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=ranlib PREFIX=/usr/local install
RUN make CC=aarch64-linux-gnu-gcc FC=aarch64-linux-gnu-gfortran HOSTCC=gcc TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=ranlib PREFIX=/usr/local install

WORKDIR /shared/
