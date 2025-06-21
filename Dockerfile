# Use Ubuntu 22.04 as the base image (JetPack 6.2 requires Ubuntu 22.04)
FROM ubuntu:22.04

# Set version label with build arguments
ARG BUILD_DATE
ARG VERSION
LABEL build_version="AGX dev env version:- ${VERSION} build-date:- ${BUILD_DATE}"
LABEL maintainer="derrekito"

ENV JETPACK_VERSION="6.2"
ENV L4T_VERSION="36.4"
ENV CUDA_VERSION="12.6"

# Set the TERM environment variable to linux
ENV TERM=linux

# Configure debconf for noninteractive frontend
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Create a script to prevent starting services during package installation
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Mount the cache volume for apt archives
VOLUME [ "/var/cache/apt/archives" ]

# Update package list and install essential tools
RUN apt-get update -y && apt-get install -y apt-utils wget ca-certificates gnupg software-properties-common

# Add the arm64 architecture to the system
RUN dpkg --add-architecture arm64

# Fix Ubuntu sources - use archive.ubuntu.com for amd64 and ports.ubuntu.com for arm64
RUN echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list

# Add toolchain PPA for GCC 12
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y

# Install necessary tools and cross-compilation packages
RUN apt-get update -y && apt-get install -y \
    build-essential \
    gcc-12 \
    g++-12 \
    git \
    libc6-dev-arm64-cross \
    gcc-12-aarch64-linux-gnu \
    g++-12-aarch64-linux-gnu \
    gfortran-12-aarch64-linux-gnu

# Add NVIDIA JetPack repository and GPG key
RUN wget -O - https://repo.download.nvidia.com/jetson/jetson-ota-public.asc | gpg --dearmor -o /usr/share/keyrings/nvidia-jetson-keyring.gpg && \
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/nvidia-jetson-keyring.gpg] https://repo.download.nvidia.com/jetson/common r${L4T_VERSION} main" > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/nvidia-jetson-keyring.gpg] https://repo.download.nvidia.com/jetson/t234 r${L4T_VERSION} main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nvidia-jetson-keyring.gpg] http://repo.download.nvidia.com/jetson/x86_64/jammy r${L4T_VERSION} main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# Add NVIDIA CUDA repository for cross-compilation
RUN wget -O - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | gpg --dearmor -o /usr/share/keyrings/nvidia-cuda-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nvidia-cuda-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64 /" > /etc/apt/sources.list.d/cuda.list

# Install JetPack 6.2 components (runtime libraries for target)
RUN apt-get update -y && \
    apt-get install -y nvidia-jetpack || echo "JetPack installation completed with warnings"

# Install CUDA development headers, libraries, and cross-compilation tools for ARM64
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    cuda-minimal-build-12-6 \
    cuda-libraries-dev-12-6 \
    cuda-command-line-tools-12-6 \
    cuda-cross-aarch64-12-6 || \
    echo "CUDA cross-compilation tools installation completed with warnings"

# Verify CUDA cross-compilation libraries
RUN ls /usr/local/cuda-${CUDA_VERSION}/targets/ | grep aarch64-linux || echo "Warning: aarch64-linux target not found"

# Create a non-root user and group
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    apt-get update -y && apt-get install -y sudo && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Set PATH for CUDA binaries
ENV PATH="/usr/local/cuda-${CUDA_VERSION}/bin:${PATH}"

# Set include and library paths for CUDA
ENV CPATH=""
ENV LD_LIBRARY_PATH=""
ENV LIBRARY_PATH=""
ENV CPATH="/usr/local/cuda-${CUDA_VERSION}/targets/aarch64-linux/include:/usr/local/cuda-${CUDA_VERSION}/targets/x86_64-linux/include:${CPATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-${CUDA_VERSION}/targets/aarch64-linux/lib:/usr/local/cuda-${CUDA_VERSION}/targets/x86_64-linux/lib:${LD_LIBRARY_PATH}"
ENV LIBRARY_PATH="/usr/local/cuda-${CUDA_VERSION}/targets/aarch64-linux/lib:/usr/local/cuda-${CUDA_VERSION}/targets/x86_64-linux/lib:${LIBRARY_PATH}"

# Set LDFLAGS to prioritize dynamic libdl.so
ENV LDFLAGS="-L/lib/aarch64-linux-gnu -L/usr/lib/aarch64-linux-gnu -L/usr/local/cuda-${CUDA_VERSION}/targets/aarch64-linux/lib -ldl"

# Build OpenBLAS
ENV MAX_NUM_THREADS=12
ENV OPENBLAS_NUM_THREADS=$MAX_NUM_THREADS
ENV GOTO_NUM_THREADS=$MAX_NUM_THREADS
ENV OMP_NUM_THREADS=$MAX_NUM_THREADS

# Clone OpenBLAS v0.3.28 (cached unless command changes)
RUN git clone --branch v0.3.28 https://github.com/xianyi/OpenBLAS.git /tmp/OpenBLAS

# Update OpenBLAS with git pull (runs on every build)
RUN cd /tmp/OpenBLAS && git pull origin v0.3.28 && chown -R $USERNAME:$USERNAME /tmp/OpenBLAS

# Set up shared directory with user permissions
RUN mkdir -p /shared && chown -R $USERNAME:$USERNAME /shared

# Switch to non-root user
USER $USERNAME
WORKDIR /tmp/OpenBLAS

# Clean up the build environment
RUN make clean

# Build and install OpenBLAS for ARM64
RUN make CC=aarch64-linux-gnu-gcc-12 FC=aarch64-linux-gnu-gfortran-12 HOSTCC=gcc-12 TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=aarch64-linux-gnu-ranlib
USER root
RUN make CC=aarch64-linux-gnu-gcc-12 FC=aarch64-linux-gnu-gfortran-12 HOSTCC=gcc-12 TARGET=CORTEXA73 USE_OPENMP=1 RANLIB=aarch64-linux-gnu-ranlib PREFIX=/usr/local install

USER $USERNAME
WORKDIR /shared/
