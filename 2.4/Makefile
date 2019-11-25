-include ../tests/env_make

FROM ?= httpd:2.4.35-alpine
VERSION ?= 2.4
SOFTWARE_VERSION ?= $(VERSION)
BUILD_TAG ?= $(VERSION)

REPO ?= docksal/apache
NAME ?= docksal-apache-$(VERSION)

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean release

build:
	docker build -t $(REPO):$(BUILD_TAG) --build-arg FROM=$(FROM) .

test:
	IMAGE=$(REPO):$(BUILD_TAG) REPO=$(REPO) NAME=$(NAME) ../tests/test.bats

push:
	docker push $(REPO):$(BUILD_TAG)

shell: clean
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(BUILD_TAG) /bin/bash

run: clean
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(BUILD_TAG)

start: clean
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(BUILD_TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME) >/dev/null 2>&1 || true

release:
    @$(TRAVIS_BUILD_DIR)/scripts/docker-push.sh

default: build
