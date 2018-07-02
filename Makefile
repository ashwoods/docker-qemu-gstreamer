SHELL := /bin/bash

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

REPO ?= qemu-gstreamer
DOCKER_REGISTRY ?= ashwoods
VERSION ?= 1.0.0
BASE ?= ashwoods/qemu-python


# DOCKER TASKS
pre-build: ## prepare qemu - remove `arm` for now
	for target_arch in aarch64 x86_64 arm; do \
  		curl -L https://github.com/multiarch/qemu-user-static/releases/download/v2.12.0/x86_64_qemu-$$target_arch-static.tar.gz | tar -zx ; \
	done

build: ## Build the container - removed `arm32v6` for now
	for docker_arch in arm64v8 amd64 ; do \
		case $$docker_arch in \
			amd64   ) qemu_arch="x86_64" ;; \
			arm32v6 ) qemu_arch="arm" ;; \
			arm64v8 ) qemu_arch="aarch64" ;; \
		esac ;  docker build --build-arg BASE=$(BASE):$$docker_arch-latest --build-arg QEMU_ARCH=$$qemu_arch -t $(DOCKER_REGISTRY)/$(REPO):$$docker_arch-latest . ; done 

manifest: ## Create docker manifest file
	docker manifest create \
		$(DOCKER_REGISTRY)/$(REPO):latest \
		$(DOCKER_REGISTRY)/$(REPO):amd64-latest \
		$(DOCKER_REGISTRY)/$(REPO):arm64v8-latest
	docker manifest annotate $(DOCKER_REGISTRY)/$(REPO):latest $(DOCKER_REGISTRY)/$(REPO):arm64v8-latest --os linux --arch arm64 --variant armv8
	docker manifest push $(DOCKER_REGISTRY)/$(REPO):latest

run: ## Run container
	docker run --rm  --name="$(REPO)" $(REPO)

release: build publish manifest ## Make a release by building and publishing the `{version}` ans `latest` tagged containers

# Docker publish
publish:  ## Publish the `{version}` ans `latest` tagged containers
	for docker_arch in arm64v8 amd64 ; do \
		docker push $(DOCKER_REGISTRY)/$(REPO):$$docker_arch-latest ; \
	done