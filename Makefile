.DEFAULT_GOAL := help

CUDA_VERSION       ?= 12.6
TAG           := cudatools:$(CUDA_VERSION)
CONTAINER     := cudatools-$(CUDA_VERSION)
CONTAINER_DIR := /shared
APT_CACHE     := apt-cache

.PHONY: help build create attach run stop clean

help:
	@echo ""
	@echo "CUDA Docker Environment (CUDA_VERSION=$(CUDA_VERSION))"
	@echo ""
	@echo "  build      Build the Docker image"
	@echo "  create     Create the container (requires LOCAL_DIR)"
	@echo "  attach     Attach to existing container (starts it)"
	@echo "  run        Remove old, create, and attach (composed)"
	@echo "  stop       Stop the container"
	@echo "  clean      Force-remove the container"
	@echo ""
	@echo "Usage: make run LOCAL_DIR=/absolute/path"

build:
	docker build --tag "$(TAG)" --build-arg APT_CACHE_VOLUME=$(APT_CACHE) .

create:
	@if [ -z "$(LOCAL_DIR)" ]; then \
		echo "Error: LOCAL_DIR is required"; exit 1; \
	fi; \
	{ docker rm -f "$(CONTAINER)" 2>/dev/null || true; } \
	&& docker create -it --hostname orin-compiler \
		-v "$(LOCAL_DIR):$(CONTAINER_DIR)" \
		-v $(APT_CACHE):/var/cache/apt/archives \
		--name "$(CONTAINER)" "$(TAG)"

attach:
	docker start -ai "$(CONTAINER)"

run: create attach

stop:
	docker stop "$(CONTAINER)"

clean:
	-docker rm -f "$(CONTAINER)"

